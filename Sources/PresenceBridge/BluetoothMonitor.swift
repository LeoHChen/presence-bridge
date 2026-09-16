import CoreBluetooth
import Combine
import PresenceCore

/// Public Core Bluetooth only. Connects exclusively to the device the user selected.
final class BluetoothMonitor: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    struct Device: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var lastSeen: TimeInterval
        var connectable: Bool
    }

    @Published private(set) var devices: [Device] = []
    @Published private(set) var status = "Bluetooth monitoring is off"
    @Published private(set) var connectionStatus = "No device selected"
    @Published private(set) var sampleCount = 0
    @Published private(set) var lastRSSI: Int?
    private var central: CBCentralManager?
    private var enabled = false
    private var activeConnection = true
    private var selected: UUID?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var monitored: CBPeripheral?
    private var timer: Timer?
    private var connectingSince: TimeInterval?
    private var nextAttempt: TimeInterval = 0
    private var requestedRSSIAt: TimeInterval?
    private var lastRSSIRequest: TimeInterval = -.infinity
    private var lastConnectedSample: TimeInterval?
    private var signal = DevicePresence()
    private var farThreshold = -78.0

    var isEnabled: Bool { enabled }
    var smoothedRSSI: Double? { signal.smoothedRSSI }
    var readyToArm: Bool { signal.readyToArm(at: now) }
    var currentFarThreshold: Double { farThreshold }
    var selectedDevice: Device? { devices.first { $0.id == selected } }
    var selectedDeviceAvailable: Bool {
        selectedDevice.map { now - $0.lastSeen <= 10 } ?? false
    }
    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    func start(selected: UUID?) {
        stop()
        self.selected = selected
        enabled = true
        resetSignal()
        let polling = Timer(timeInterval: 2, repeats: true) { [weak self] _ in self?.poll() }
        RunLoop.main.add(polling, forMode: .common)
        timer = polling
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main)
        } else {
            centralManagerDidUpdateState(central!)
        }
    }

    func select(_ identifier: UUID?) {
        detach()
        selected = identifier
        resetSignal()
        nextAttempt = 0
        recoverSelectedPeripheral()
        sortDevices()
        poll()
    }

    func setActiveConnection(_ active: Bool) {
        activeConnection = active
        select(selected)
    }

    /// Calibrate while the chosen device is at the desk.
    @discardableResult func calibrateAtDesk() -> Bool {
        guard sampleCount >= 3, let value = signal.smoothedRSSI,
              proximity(at: now) != .far else { return false }
        farThreshold = max(-100, min(-45, value - 15))
        resetSignal()
        status = "Calibrated: leave threshold \(Int(farThreshold)) dBm; collect three fresh samples"
        return true
    }

    func setFarThreshold(_ value: Double) {
        farThreshold = min(-45, max(-100, value))
        resetSignal()
    }

    func stop() {
        enabled = false
        timer?.invalidate()
        timer = nil
        central?.stopScan()
        detach()
        peripherals = [:]
        devices = []
        resetSignal()
        status = "Bluetooth monitoring is off"
    }

    func proximity(at time: TimeInterval) -> Proximity {
        guard selected != nil, enabled else { return .unavailable }
        return signal.proximity(at: time)
    }

    private func resetSignal() {
        signal = DevicePresence(farThreshold: farThreshold)
        signal.setRadioAvailable(central?.state == .poweredOn, at: now)
        sampleCount = 0
        lastRSSI = nil
        lastConnectedSample = nil
    }

    private func detach() {
        if let old = monitored {
            old.delegate = nil
            if old.state != .disconnected { central?.cancelPeripheralConnection(old) }
        }
        monitored = nil
        connectingSince = nil
        requestedRSSIAt = nil
        lastRSSIRequest = -.infinity
        connectionStatus = "No active connection"
    }

    private func recoverSelectedPeripheral() {
        guard enabled, central?.state == .poweredOn, let selected else { return }
        if let known = peripherals[selected] ?? central?.retrievePeripherals(withIdentifiers: [selected]).first {
            monitored = known
            known.delegate = self
        }
    }

    private func poll() {
        guard enabled, central?.state == .poweredOn, selected != nil else { return }
        if monitored == nil { recoverSelectedPeripheral() }
        guard let peripheral = monitored else {
            connectionStatus = "Waiting to discover the selected device"
            return
        }
        guard activeConnection else { connectionStatus = "Passive advertisements only"; return }
        switch peripheral.state {
        case .connected:
            connectingSince = nil
            if let pending = requestedRSSIAt, now - pending >= 6 {
                connectionStatus = "RSSI stalled; reconnecting"
                central?.cancelPeripheralConnection(peripheral)
                requestedRSSIAt = nil
                nextAttempt = now + 5
            } else if requestedRSSIAt == nil && now - lastRSSIRequest >= 2 {
                requestedRSSIAt = now
                lastRSSIRequest = now
                peripheral.readRSSI()
            }
        case .connecting:
            if let started = connectingSince, now - started >= 15 {
                central?.cancelPeripheralConnection(peripheral)
                connectingSince = nil
                nextAttempt = now + 5
                connectionStatus = "Connection timed out; using advertisements while retrying"
            }
        case .disconnected:
            guard now >= nextAttempt else { return }
            if devices.first(where: { $0.id == peripheral.identifier })?.connectable == false {
                connectionStatus = "Device advertises as nonconnectable; passive fallback"
                return
            }
            peripheral.delegate = self
            connectingSince = now
            connectionStatus = "Connecting to the selected device…"
            central?.connect(peripheral, options: nil)
        case .disconnecting: break
        @unknown default: break
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard enabled else { central.stopScan(); return }
        signal.setRadioAvailable(central.state == .poweredOn, at: now)
        switch central.state {
        case .poweredOn:
            status = "Bluetooth ready; select your iPhone or Apple Watch"
            central.scanForPeripherals(withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            // Retrieve only already connected peripherals exposing standard public services.
            for peripheral in central.retrieveConnectedPeripherals(withServices: [CBUUID(string: "1800"), CBUUID(string: "180A")]) {
                remember(peripheral, name: peripheral.name, rssi: 127, connectable: true)
            }
            recoverSelectedPeripheral()
            poll()
        case .unauthorized:
            status = "Bluetooth permission required in System Settings"
        case .poweredOff:
            status = "Bluetooth is off; an armed device session treats prolonged loss as departure"
        default:
            status = "Bluetooth unavailable or starting"
        }
    }

    private func remember(_ peripheral: CBPeripheral, name: String?, rssi: Int, connectable: Bool) {
        devices.removeAll { $0.id != selected && now - $0.lastSeen > 45 }
        let retained = Set(devices.map(\.id)).union(selected.map { [$0] } ?? [])
        peripherals = peripherals.filter { retained.contains($0.key) }
        if peripheral.identifier == selected { peripherals[peripheral.identifier] = peripheral }

        guard let clean = BluetoothDeviceCatalog.meaningfulName(name) else {
            // Unnamed advertisements are intentionally absent from the picker. Keep only the
            // selected peripheral so a selection restored from preferences can still reconnect.
            devices.removeAll { $0.id == peripheral.identifier && peripheral.identifier != selected }
            return
        }
        let device = Device(id: peripheral.identifier, name: clean, rssi: rssi, lastSeen: now, connectable: connectable)
        if let index = devices.firstIndex(where: { $0.id == device.id }) { devices[index] = device }
        else if devices.count < 50 { devices.append(device) }
        else {
            func priority(_ item: Device) -> Int {
                item.rssi == 127 ? -127 : item.rssi
            }
            if let weakest = devices.indices.filter({ devices[$0].id != selected })
                .min(by: { priority(devices[$0]) < priority(devices[$1]) }),
               priority(device) > priority(devices[weakest]) {
                peripherals.removeValue(forKey: devices[weakest].id)
                devices[weakest] = device
            }
        }
        if devices.contains(where: { $0.id == device.id }) { peripherals[device.id] = peripheral }
        sortDevices()
    }

    private func sortDevices() {
        let order = BluetoothDeviceCatalog.sorted(devices.map {
            BluetoothDeviceCandidate(identifier: $0.id, name: $0.name, rssi: $0.rssi,
                                     lastSeen: $0.lastSeen, isSelected: $0.id == selected)
        }).map(\.identifier)
        devices.sort { lhs, rhs in
            (order.firstIndex(of: lhs.id) ?? order.count) < (order.firstIndex(of: rhs.id) ?? order.count)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard enabled else { return }
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        let connectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? true
        remember(peripheral, name: name, rssi: RSSI.intValue, connectable: connectable)
        guard peripheral.identifier == selected else { return }
        if monitored == nil { monitored = peripheral; peripheral.delegate = self }
        // Prefer fresh connection RSSI; advertisements are a fallback while connecting.
        if lastConnectedSample == nil || now - lastConnectedSample! > 6 { observe(RSSI.intValue) }
        poll()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard enabled, peripheral === monitored, peripheral.identifier == selected else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        connectingSince = nil
        requestedRSSIAt = nil
        connectionStatus = "Connected; reading signal every two seconds"
        poll()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard peripheral === monitored else { return }
        connectingSince = nil
        requestedRSSIAt = nil
        nextAttempt = now + 5
        connectionStatus = "Connection rejected; passive fallback and retry in five seconds"
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard enabled, peripheral === monitored else { return }
        connectingSince = nil
        requestedRSSIAt = nil
        nextAttempt = max(nextAttempt, now + 2)
        connectionStatus = "Disconnected; signal expiry continues while reconnecting"
        // Preserve freshness: disconnection must not reset the departure clock.
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard enabled, peripheral === monitored, peripheral.identifier == selected else { return }
        requestedRSSIAt = nil
        guard error == nil, (-127 ... -1).contains(RSSI.intValue) else { return }
        lastConnectedSample = now
        connectionStatus = "Connected; signal \(RSSI.intValue) dBm"
        observe(RSSI.intValue)
    }

    private func observe(_ value: Int) {
        guard (-127 ... -1).contains(value) else { return }
        signal.observe(rssi: value, at: now)
        sampleCount = signal.sampleCount
        lastRSSI = signal.lastRSSI
        if let selected, let index = devices.firstIndex(where: { $0.id == selected }) {
            devices[index].rssi = value
            devices[index].lastSeen = now
            sortDevices()
        }
    }
}
