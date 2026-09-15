import SwiftUI
import ServiceManagement
import PresenceCore

@main
enum Launcher {
    @MainActor static func main() {
        if CommandLine.arguments.contains("--self-check") {
            var engine = PresenceEngine()
            precondition(engine.update(.init(time: 0, idleSeconds: 0)) == .present)
            print("Presence Bridge self-check passed; no sensors or effects started.")
            return
        }
        if let index = CommandLine.arguments.firstIndex(of: "--diagnose-bluetooth") {
            BluetoothDiagnostic.run(arguments: Array(CommandLine.arguments[index...]))
            return
        }
        PresenceBridgeApp.main()
    }
}

struct PresenceBridgeApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Presence Bridge", id: "control-panel") {
            ControlPanel(model: model)
        }
        .defaultSize(width: 420, height: 760)
        MenuBarExtra("Presence Bridge", systemImage: model.armed ? "person.crop.circle.badge.checkmark" : "person.crop.circle") {
            ControlPanel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

struct ControlPanel: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Presence Bridge").font(.title3.bold())
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(model.walkTestRunning ? "DETECTION TEST" :
                         model.armed ? (model.needsReturnConfirmation ? "WAITING" : "ACTIVE") : "OBSERVING")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text(model.needsReturnConfirmation
                     ? (model.armed && model.resumeAfterUnlock ? "Waiting to resume" : "Return needs confirmation")
                     : model.state.rawValue.capitalized)
                    .font(.headline)
                Text("Idle \(Int(min(model.idleSeconds, 99999)))s · Bluetooth \(model.proximity.rawValue)")
                    .font(.caption.monospacedDigit())
                Text(model.effectStatus).font(.caption).foregroundStyle(.secondary)
                if model.walkTestRunning {
                    Text("Automatic locking is paused during this detection test. Choose Start work to arm it.")
                        .font(.caption)
                }

                HStack {
                    Button(model.needsReturnConfirmation ? "I’m back" : "Start work") { model.startWork() }
                        .disabled(model.quitting)
                    Button("Pause") { model.pause() }.disabled(!model.armed && !model.walkTestRunning)
                    Button("Lock now") { model.requestLock() }.disabled(model.quitting)
                }
                Divider()
                Toggle("Lock automatically when away", isOn: $model.lockEnabled)
                Toggle("Resume after unlocking", isOn: $model.resumeAfterUnlock)
                if model.lockEnabled && !ScreenLocker.authorized {
                    Button("Grant Accessibility for locking") { ScreenLocker.requestPermission() }
                    Text("Locking sends Control-Command-Q. Confirm it works on your Mac.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Toggle("Run shared Focus shortcuts", isOn: $model.focusEnabled)
                Text("Shared Focus also affects your Mac. Create the three shortcuts in the setup guide first.")
                    .font(.caption).foregroundStyle(.secondary)
                Text(model.focusStatus).font(.caption)
                HStack {
                    Text("Idle timeout")
                    Spacer()
                    Text("\(Int(model.idleTimeout / 60)) min").monospacedDigit()
                }
                Slider(value: $model.idleTimeout, in: 60...1800, step: 60)
                Text(model.bluetoothEnabled
                    ? "Bluetooth departure: 5 seconds without input, then an 8-second grace period. Missing signal expires after 8 seconds."
                    : "Idle departure adds a 15-second grace period.")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Toggle("Use iPhone / Watch proximity", isOn: Binding(
                    get: { model.bluetoothEnabled }, set: { model.setBluetooth($0) }))
                Text(model.bluetooth.status).font(.caption).foregroundStyle(.secondary)
                if model.bluetoothEnabled {
                    Toggle("Maintain an active Bluetooth connection", isOn: Binding(
                        get: { model.activeBluetooth }, set: { model.setActiveBluetooth($0) }))
                    Text(model.bluetooth.connectionStatus).font(.caption)
                    Menu("\(model.selectedDevice == nil ? "Choose advertising device" : "Change selected device")") {
                        Button("Use idle detection only") { model.selectDevice(nil) }
                        ForEach(model.bluetooth.devices) { device in
                            Button("\(device.name) · \(device.rssi == 127 ? "known device" : String(device.rssi) + " dBm") · \(device.id.uuidString.prefix(6))") {
                                model.selectDevice(device.id)
                            }
                        }
                    }
                    if let id = model.selectedDevice {
                        Text("Selected: \(id.uuidString.prefix(8))").font(.caption.monospaced())
                    }
                    Text("Signal: \(model.bluetooth.smoothedRSSI.map { String(Int($0)) + " dBm" } ?? "waiting") · \(model.bluetooth.sampleCount) samples")
                        .font(.caption.monospacedDigit())
                    HStack {
                        Button("Calibrate at desk") { model.calibrateAtDesk() }
                        Button("Test detection only") { model.startWalkTest() }
                    }
                    HStack {
                        Text("Leave threshold")
                        Spacer()
                        Text("\(Int(model.bluetooth.currentFarThreshold)) dBm").monospacedDigit()
                    }.font(.caption)
                    Slider(value: Binding(get: { model.bluetooth.currentFarThreshold },
                        set: { model.setFarThreshold($0) }), in: -100 ... -45, step: 1)
                    Text("A less-negative threshold locks at a stronger signal. Calibrate and test first. Device compatibility varies; Apple’s Auto Unlock is a separate feature.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                HStack {
                    Button("Open panel") { openWindow(id: "control-panel") }
                    Menu("Launch at login") {
                        Button("Enable") { model.setLaunchAtLogin(true) }
                        Button("Disable") { model.setLaunchAtLogin(false) }
                    }
                    Link("Setup guide", destination: URL(string: "https://github.com/LeoHChen/presence-bridge/blob/main/docs/shortcuts.md")!)
                    Spacer()
                    Button(model.quitting ? "Quitting…" : "Quit") { model.quit() }.disabled(model.quitting)
                }
                Text("After a detected lock and unlock, an active session resumes when your device is near. If return detection is unavailable, choose I’m back. Pause stays paused. Bluetooth never unlocks the Mac.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .frame(width: 420, height: 760)
    }
}
