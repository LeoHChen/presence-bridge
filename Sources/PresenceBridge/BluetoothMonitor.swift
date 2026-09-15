import CoreBluetooth
import Combine
import PresenceCore

final class BluetoothMonitor: NSObject, ObservableObject, CBCentralManagerDelegate {
    struct Device: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var lastSeen: TimeInterval
    }

    @Published private(set) var devices: [Device] = []
    @Published private(set) var status = "Bluetooth scanning is off"
    private var central: CBCentralManager?
    private var enabled = false
    private var selected: UUID?
    private var filter = ProximityFilter()

    var isEnabled: Bool { enabled }
    var smoothedRSSI: Double? { filter.smoothedRSSI }

    func start(selected: UUID?) {
        self.selected = selected
        enabled = true
        filter = ProximityFilter()
        devices = []
        if central == nil {
            central = CBCentralManager(delegate: self, queue: .main)
        } else {
            centralManagerDidUpdateState(central!)
        }
    }

    func select(_ identifier: UUID?) {
        selected = identifier
        filter = ProximityFilter()
    }

    func stop() {
        enabled = false
        central?.stopScan()
        filter = ProximityFilter()
        devices = []
        status = "Bluetooth scanning is off"
    }

    func proximity(at time: TimeInterval) -> Proximity {
        guard selected != nil, enabled else { return .unavailable }
        return filter.proximity(at: time, radioAvailable: central?.state == .poweredOn)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard enabled else { central.stopScan(); return }
        filter = ProximityFilter()
        switch central.state {
        case .poweredOn:
            status = "Scanning advertising BLE devices"
            central.scanForPeripherals(withServices: nil,
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        case .unauthorized: status = "Bluetooth permission denied; using idle detection"
        case .poweredOff: status = "Bluetooth is off; using idle detection"
        case .unsupported: status = "Bluetooth unavailable; using idle detection"
        default: status = "Bluetooth is starting; using idle detection"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard enabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let rssi = RSSI.intValue
        guard (-127 ... -1).contains(rssi) else { return }
        if peripheral.identifier == selected { filter.observe(rssi: rssi, at: now) }
        let rawName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name ?? "Unnamed device"
        let name = String(rawName.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
            .map(String.init).joined().prefix(60))
        let device = Device(id: peripheral.identifier, name: name, rssi: rssi, lastSeen: now)
        devices.removeAll { now - $0.lastSeen > 30 }
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else if devices.count < 50 {
            devices.append(device)
        }
    }
}
