import AppKit
import Combine
import CoreBluetooth
import CoreGraphics
import PresenceCore

/// Explicit local diagnostic: never arms effects, locks, or invokes Shortcuts.
@MainActor
enum BluetoothDiagnostic {
    static func run(arguments: [String]) {
        _ = NSApplication.shared
        NSApplication.shared.setActivationPolicy(.accessory)
        let seconds = min(300, max(10, arguments.dropFirst().first.flatMap(Double.init) ?? 40))
        let requestedName: String? = arguments.firstIndex(of: "--device-name").flatMap {
            arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil
        }
        let monitor = BluetoothMonitor()
        var statusSubscription: AnyCancellable?
        statusSubscription = monitor.$status.removeDuplicates().sink { print("Bluetooth: \($0)"); fflush(stdout) }
        let connectionSubscription = monitor.$connectionStatus.removeDuplicates().sink {
            print("Connection: \($0)"); fflush(stdout)
        }
        print("Local Bluetooth diagnostic for \(Int(seconds)) seconds. Effects disabled.")
        print("Authorization: \(CBManager.authorization.rawValue). Approve the macOS Bluetooth prompt if shown.")
        fflush(stdout)
        monitor.start(selected: nil)
        let finish = ProcessInfo.processInfo.systemUptime + seconds
        var lastReport = -Double.infinity
        var selected = false
        var engine = PresenceEngine(policy: .init(departureGrace: 8, activityVeto: 5, useBluetooth: true))
        var previousState: PresenceState?
        while ProcessInfo.processInfo.systemUptime < finish {
            RunLoop.main.run(until: Date().addingTimeInterval(0.2))
            let now = ProcessInfo.processInfo.systemUptime
            if let requestedName, !selected {
                let matches = monitor.devices.filter { $0.name == requestedName }
                if matches.count == 1 {
                    monitor.select(matches[0].id)
                    selected = true
                    print("Monitoring explicitly requested device: \(requestedName)")
                }
            }
            if now - lastReport >= 5 {
                lastReport = now
                let named = monitor.devices.filter { $0.name != "Unnamed device" }
                if requestedName == nil {
                    print("Devices: \(monitor.devices.count); named: " + named.prefix(20)
                        .map { "\($0.name) (\($0.rssi) dBm)" }.joined(separator: "; "))
                } else if !selected { print("Waiting for the requested device to advertise…") }
                if selected {
                    print("Presence: \(monitor.proximity(at: now).rawValue); RSSI: \(monitor.smoothedRSSI.map { String(Int($0)) } ?? "unknown")")
                }
                fflush(stdout)
            }
            if selected {
                let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState,
                    eventType: CGEventType(rawValue: UInt32.max)!)
                let state = engine.update(.init(time: now, idleSeconds: idle, proximity: monitor.proximity(at: now)))
                if state != previousState {
                    print("Walk test state: \(state.rawValue); idle \(Int(idle))s; effects disabled")
                    previousState = state
                    fflush(stdout)
                }
            }
        }
        monitor.stop()
        withExtendedLifetime((statusSubscription, connectionSubscription)) {}
        print("Diagnostic complete. No lock or Focus actions ran.")
    }
}
