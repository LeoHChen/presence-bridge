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
        PresenceBridgeApp.main()
    }
}

struct PresenceBridgeApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("Presence Bridge", systemImage: model.armed ? "person.crop.circle.badge.checkmark" : "person.crop.circle") {
            ControlPanel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

struct ControlPanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Presence Bridge").font(.title3.bold())
                    Spacer()
                    Text(model.armed ? "ACTIVE" : "OBSERVING").font(.caption).foregroundStyle(.secondary)
                }
                Text(model.needsReturnConfirmation ? "Return needs confirmation" : model.state.rawValue.capitalized)
                    .font(.headline)
                Text("Idle \(Int(min(model.idleSeconds, 99999)))s · Bluetooth \(model.proximity.rawValue)")
                    .font(.caption.monospacedDigit())
                Text(model.effectStatus).font(.caption).foregroundStyle(.secondary)

                HStack {
                    Button(model.needsReturnConfirmation ? "I’m back" : "Start work") { model.startWork() }
                        .disabled(model.quitting)
                    Button("Pause") { model.pause() }.disabled(!model.armed)
                    Button("Lock now") { model.requestLock() }.disabled(model.quitting)
                }
                Divider()
                Toggle("Lock automatically when away", isOn: $model.lockEnabled)
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
                Text("Departure adds a 15-second grace period. Bluetooth departure also requires 30 seconds without input.")
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                Toggle("Scan Bluetooth (experimental)", isOn: Binding(
                    get: { model.bluetoothEnabled }, set: { model.setBluetooth($0) }))
                Text(model.bluetooth.status).font(.caption).foregroundStyle(.secondary)
                if model.bluetoothEnabled {
                    Menu("\(model.selectedDevice == nil ? "Choose advertising device" : "Change selected device")") {
                        Button("Use idle detection only") { model.selectDevice(nil) }
                        ForEach(model.bluetooth.devices) { device in
                            Button("\(device.name) · \(device.rssi) dBm · \(device.id.uuidString.prefix(6))") {
                                model.selectDevice(device.id)
                            }
                        }
                    }
                    if let id = model.selectedDevice {
                        Text("Selected: \(id.uuidString.prefix(8))").font(.caption.monospaced())
                    }
                    Text("Apple Watch Auto Unlock signals are unavailable. An iPhone may not advertise consistently. Use a tested BLE beacon.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                HStack {
                    Menu("Launch at login") {
                        Button("Enable") { model.setLaunchAtLogin(true) }
                        Button("Disable") { model.setLaunchAtLogin(false) }
                    }
                    Link("Setup guide", destination: URL(string: "https://github.com/LeoHChen/presence-bridge/blob/main/docs/shortcuts.md")!)
                    Spacer()
                    Button(model.quitting ? "Quitting…" : "Quit") { model.quit() }.disabled(model.quitting)
                }
                Text("After locking or sleep, unlock your Mac and choose I’m back. Bluetooth never unlocks the Mac.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .frame(width: 400, height: 680)
    }
}
