import AppKit
import Combine
import CoreGraphics
import ServiceManagement
import PresenceCore

@MainActor
final class AppModel: NSObject, ObservableObject {
    @Published private(set) var state: PresenceState = .unknown
    @Published private(set) var idleSeconds: Double = 0
    @Published private(set) var proximity: Proximity = .unavailable
    @Published private(set) var armed = false
    @Published private(set) var needsReturnConfirmation = false
    @Published private(set) var effectStatus = "Observation mode: no lock or Focus changes"
    @Published private(set) var focusStatus = "Focus bridge is off"
    @Published private(set) var quitting = false
    @Published private(set) var walkTestRunning = false
    @Published var lockEnabled = false {
        didSet {
            if lockEnabled && armed && bluetoothEnabled {
                pause()
                effectStatus = "Locking enabled. Confirm the device is near, then choose Start work."
            }
        }
    }
    @Published var focusEnabled = false
    @Published var idleTimeout: Double {
        didSet { UserDefaults.standard.set(idleTimeout, forKey: "idleTimeout") }
    }
    @Published private(set) var bluetoothEnabled = false
    @Published private(set) var selectedDevice: UUID?
    @Published private(set) var activeBluetooth = true
    let bluetooth = BluetoothMonitor()
    private var engine = PresenceEngine()
    private var focus = FocusPolicy()
    private let shortcuts = ShortcutRunner()
    private var timer: Timer?
    private var screenAwake = true
    private var sessionActive = true
    private var lockedThisSession = false
    private var forwarding: AnyCancellable?

    override init() {
        let savedTimeout = UserDefaults.standard.double(forKey: "idleTimeout")
        idleTimeout = savedTimeout >= 60 && savedTimeout <= 1800 ? savedTimeout : 300
        selectedDevice = UserDefaults.standard.string(forKey: "selectedDevice").flatMap(UUID.init(uuidString:))
        super.init()
        forwarding = bluetooth.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {
            center.addObserver(self, selector: #selector(unavailable(_:)), name: name, object: nil)
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification,
                     NSWorkspace.sessionDidBecomeActiveNotification] {
            center.addObserver(self, selector: #selector(available(_:)), name: name, object: nil)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        tick()
    }

    func setBluetooth(_ enabled: Bool) {
        if armed || walkTestRunning { pause() }
        bluetoothEnabled = enabled
        if enabled { bluetooth.start(selected: selectedDevice) } else { bluetooth.stop() }
        engine.reset()
    }

    func selectDevice(_ identifier: UUID?) {
        if armed || walkTestRunning { pause() }
        selectedDevice = identifier
        UserDefaults.standard.set(identifier?.uuidString, forKey: "selectedDevice")
        bluetooth.select(identifier)
        engine.reset()
    }

    func setActiveBluetooth(_ active: Bool) {
        if armed || walkTestRunning { pause() }
        activeBluetooth = active
        bluetooth.setActiveConnection(active)
        engine.reset()
    }

    func calibrateAtDesk() {
        if armed || walkTestRunning { pause() }
        effectStatus = bluetooth.calibrateAtDesk()
            ? "Desk signal saved. Wait for fresh samples, then test walking away."
            : "Keep the device near the Mac until at least three valid samples arrive."
        engine.reset()
    }

    func setFarThreshold(_ value: Double) {
        if armed || walkTestRunning { pause() }
        bluetooth.setFarThreshold(value)
        engine.reset()
    }

    func startWalkTest() {
        guard bluetoothEnabled, bluetooth.readyToArm else {
            effectStatus = "Select a device and wait for a near signal before the walk test."
            return
        }
        pause()
        engine.reset()
        walkTestRunning = true
        effectStatus = "Walk test: take the selected device away. Locking and Focus stay off."
        tick()
    }

    func startWork() {
        guard !quitting else { return }
        guard !(lockEnabled && bluetoothEnabled) || bluetooth.readyToArm else {
            effectStatus = "Cannot arm proximity locking yet: select your device and confirm a near signal."
            return
        }
        walkTestRunning = false
        armed = true
        needsReturnConfirmation = false
        lockedThisSession = false
        // This user interaction establishes an available desktop, including after manual unlock.
        screenAwake = true
        sessionActive = true
        engine.reset()
        focus.beginWorkSession()
        effectStatus = "Work session started"
        tick()
    }

    func pause() {
        armed = false
        walkTestRunning = false
        needsReturnConfirmation = false
        effectStatus = "Paused; cleaning up any Focus lease"
        tick()
    }

    func requestLock() {
        // Latch before posting key events: our own injected events must never imply a return.
        needsReturnConfirmation = true
        lockedThisSession = true
        effectStatus = ScreenLocker.requestLock()
            ? "Lock requested; use I’m back after unlocking"
            : "Lock failed: grant Accessibility permission, then retry"
        tick()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            effectStatus = "Login item: \(SMAppService.mainApp.status == .enabled ? "enabled" : "check System Settings")"
        } catch { effectStatus = "Login item change failed; use a stable app bundle in Applications" }
    }

    @objc private func unavailable(_ notification: Notification) {
        if notification.name == NSWorkspace.sessionDidResignActiveNotification { sessionActive = false }
        else { screenAwake = false }
        if armed { needsReturnConfirmation = true }
        engine.reset()
        tick()
    }

    @objc private func available(_ notification: Notification) {
        if notification.name == NSWorkspace.sessionDidBecomeActiveNotification { sessionActive = true }
        else { screenAwake = true }
        if bluetoothEnabled { bluetooth.start(selected: selectedDevice) }
        engine.reset()
        tick()
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState,
            eventType: CGEventType(rawValue: UInt32.max)!)
        idleSeconds = idle.isFinite && idle >= 0 ? idle : 0
        proximity = bluetooth.proximity(at: now)
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        let onConsole = session?[kCGSessionOnConsoleKey as String] as? Bool ?? false
        let loggedIn = session?[kCGSessionLoginDoneKey as String] as? Bool ?? false
        engine.policy = PresencePolicy(idleTimeout: idleTimeout,
            departureGrace: bluetoothEnabled ? 8 : 15,
            activityVeto: bluetoothEnabled ? 5 : 30,
            useBluetooth: bluetoothEnabled)
        state = engine.update(.init(time: now, idleSeconds: idle,
            proximity: proximity, sessionAvailable: screenAwake && sessionActive && onConsole && loggedIn))

        if walkTestRunning {
            if state == .away { effectStatus = "Walk-away detected. No lock was sent. Return and check the near signal." }
            else if state == .leaving { effectStatus = "Departure signal detected; counting the eight-second grace period." }
            else if state == .present { effectStatus = "Walk test: device/activity is present. Take the selected device away." }
        }

        if armed, state == .away, !needsReturnConfirmation {
            needsReturnConfirmation = true
            if lockEnabled && !lockedThisSession { requestLock(); return }
            effectStatus = "Away; use I’m back to resume effects"
        }
        let wantsFocus = armed && focusEnabled && !needsReturnConfirmation
            && (state == .present || state == .leaving)
        reconcileFocus(wantsFocus: wantsFocus, now: now)
    }

    private func reconcileFocus(wantsFocus: Bool, now: TimeInterval) {
        guard let action = focus.next(wantsFocus: wantsFocus, at: now) else { return }
        focusStatus = "Running Focus \(action.rawValue)…"
        Task { [weak self] in
            guard let self else { return }
            let result = await shortcuts.run(action)
            focus.complete(action, output: result.output, at: ProcessInfo.processInfo.systemUptime)
            focusStatus = result.message
            // Reconcile current intent after completion, including pause/away while ON was in flight.
            tick()
        }
    }

    func quit() {
        guard !quitting else { return }
        quitting = true
        pause()
        bluetooth.stop()
        Task { [weak self] in
            guard let self else { return }
            let deadline = ProcessInfo.processInfo.systemUptime + 25
            while focus.mayOwnFocus && ProcessInfo.processInfo.systemUptime < deadline {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            NSApplication.shared.terminate(nil)
        }
    }
}
