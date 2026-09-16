import AppKit
import ServiceManagement
import SwiftUI
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
        .defaultSize(width: 460, height: 800)

        MenuBarExtra("Presence Bridge", systemImage: model.menuBarSystemImage) {
            MenuBarMenu(model: model)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
private func revealControlPanelWindow() {
    guard let window = NSApplication.shared.windows.first(where: { $0.title == "Presence Bridge" }) else { return }
    if window.isMiniaturized { window.deminiaturize(nil) }
    window.makeKeyAndOrderFront(nil)
}

@MainActor
private func presentControlPanel(using openWindow: OpenWindowAction) {
    openWindow(id: "control-panel")
    NSApplication.shared.activate(ignoringOtherApps: true)
    Task { @MainActor in
        await Task.yield()
        revealControlPanelWindow()
        // A closed SwiftUI window may be created later than an existing minimized one.
        try? await Task.sleep(nanoseconds: 200_000_000)
        revealControlPanelWindow()
    }
}

struct MenuBarMenu: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(model.armed ? (model.needsReturnConfirmation ? "Waiting for return" : "Active") : "Observing")
        if let name = model.selectedDeviceName { Text("Device: \(name)") }
        if let latest = model.activityEntries.first { Text("Latest: \(latest.message)") }
        Divider()
        Button("Open Presence Bridge") { presentControlPanel(using: openWindow) }
            .keyboardShortcut("o")
        Button(model.needsReturnConfirmation ? "I’m back" : "Start work") { model.startWork() }
            .disabled(model.quitting)
        Button("Pause") { model.pause() }
            .disabled(!model.armed && !model.walkTestRunning)
        Button("Lock now") { model.requestLock() }
            .disabled(model.quitting)
        Divider()
        Button(model.quitting ? "Quitting…" : "Quit Presence Bridge") { model.quit() }
            .disabled(model.quitting)
    }
}

struct ControlPanel: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    private let navy = Color(red: 11 / 255, green: 31 / 255, blue: 51 / 255)
    private let azure = Color(red: 47 / 255, green: 128 / 255, blue: 237 / 255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                actionRow
                automationSection
                bluetoothSection
                activitySection
                footer
            }
            .padding(18)
        }
        .frame(width: 460, height: 800)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(navy.gradient)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.cyan)
                        .offset(x: 16, y: -12)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Presence Bridge").font(.title2.bold())
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development")")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(text: model.walkTestRunning ? "DETECTION TEST" :
                    model.armed ? (model.needsReturnConfirmation ? "WAITING" : "ACTIVE") : "OBSERVING",
                    active: model.armed && !model.needsReturnConfirmation)
            }

            Text(model.needsReturnConfirmation
                 ? (model.armed && model.resumeAfterUnlock ? "Waiting to resume" : "Return needs confirmation")
                 : model.state.rawValue.capitalized)
                .font(.headline)
            Text("Idle \(Int(min(model.idleSeconds, 99999)))s · Bluetooth \(model.proximity.rawValue)")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Text(model.effectStatus).font(.callout).foregroundStyle(.secondary)
            if model.walkTestRunning {
                Label("Automatic locking is paused during this detection test.", systemImage: "checkmark.shield")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var actionRow: some View {
        HStack {
            Button(model.needsReturnConfirmation ? "I’m back" : "Start work") { model.startWork() }
                .buttonStyle(.borderedProminent).tint(azure).disabled(model.quitting)
            Button("Pause") { model.pause() }.disabled(!model.armed && !model.walkTestRunning)
            Spacer()
            Button("Lock now") { model.requestLock() }.disabled(model.quitting)
        }
    }

    private var automationSection: some View {
        GroupBox("Automation") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Lock automatically when away", isOn: $model.lockEnabled)
                Toggle("Resume after unlocking", isOn: $model.resumeAfterUnlock)
                if model.lockEnabled && !ScreenLocker.authorized {
                    Button("Grant control access for locking") { ScreenLocker.requestPermission() }
                    Text("Presence Bridge sends Control-Command-Q and never unlocks the Mac.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Toggle("Run shared Focus shortcuts", isOn: $model.focusEnabled)
                Text(model.focusStatus).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Text("Idle timeout")
                    Spacer()
                    Text("\(Int(model.idleTimeout / 60)) min").monospacedDigit()
                }
                Slider(value: $model.idleTimeout, in: 60...1800, step: 60)
            }
            .padding(.top, 4)
        }
    }

    private var bluetoothSection: some View {
        GroupBox("Proximity device") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Use iPhone / Watch proximity", isOn: Binding(
                    get: { model.bluetoothEnabled }, set: { model.setBluetooth($0) }))

                if let name = model.selectedDeviceName {
                    HStack(spacing: 8) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundStyle(model.selectedDeviceAvailable ? azure : .secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name).fontWeight(.semibold).lineLimit(1)
                            Text(model.selectedDeviceAvailable ? "Selected device" : "Selected device · waiting to be seen")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(azure)
                    }
                    .padding(10)
                    .background(azure.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
                } else {
                    Label("No proximity device selected", systemImage: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }

                if model.bluetoothEnabled {
                    Text(model.bluetooth.status).font(.caption).foregroundStyle(.secondary)
                    Toggle("Maintain an active Bluetooth connection", isOn: Binding(
                        get: { model.activeBluetooth }, set: { model.setActiveBluetooth($0) }))
                    Text(model.bluetooth.connectionStatus).font(.caption).foregroundStyle(.secondary)

                    Menu(model.selectedDevice == nil ? "Choose a named device" : "Change selected device") {
                        Button("Use idle detection only") { model.selectDevice(nil) }
                        Divider()
                        if model.bluetooth.devices.isEmpty {
                            Text("Waiting for named devices…")
                        } else {
                            ForEach(model.bluetooth.devices) { device in
                                Button {
                                    model.selectDevice(device)
                                } label: {
                                    if device.id == model.selectedDevice {
                                        Label(device.name, systemImage: "checkmark")
                                    } else {
                                        Text(device.name)
                                    }
                                }
                            }
                        }
                    }
                    Text("Only devices that advertise a useful name are shown. Your selection is remembered on this Mac.")
                        .font(.caption).foregroundStyle(.secondary)

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
                    Text("Departure requires five seconds without input plus an eight-second grace period. Device compatibility varies.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }

    private var activitySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Recent activity", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                    Spacer()
                    Button("Clear") { model.clearActivityHistory() }
                        .buttonStyle(.plain).foregroundStyle(azure)
                        .disabled(model.activityEntries.isEmpty)
                }
                if model.activityEntries.isEmpty {
                    Text("Activity from this app session will appear here.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(model.activityEntries.prefix(7))) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: entry.kind.systemImage)
                                .frame(width: 14).foregroundStyle(entry.kind == .error ? .red : azure)
                            Text(entry.message).font(.caption).lineLimit(2)
                            Spacer(minLength: 6)
                            Text(entry.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
                Text("Kept in memory for this session only. No telemetry is sent.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Show in front") { presentControlPanel(using: openWindow) }
                Menu("Launch at login") {
                    Button("Enable") { model.setLaunchAtLogin(true) }
                    Button("Disable") { model.setLaunchAtLogin(false) }
                }
                Link("Setup guide", destination: URL(string: "https://github.com/LeoHChen/presence-bridge/blob/main/docs/shortcuts.md")!)
                Spacer()
                Button(model.quitting ? "Quitting…" : "Quit") { model.quit() }.disabled(model.quitting)
            }
            Text("After a detected lock and normal unlock, an active session resumes when the selected device is near. The menu-bar lock icon restores this window after it is closed or minimized.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct StatusPill: View {
    let text: String
    let active: Bool

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 5)
            .foregroundStyle(active ? .green : .secondary)
            .background((active ? Color.green : Color.secondary).opacity(0.12), in: Capsule())
    }
}

private extension ActivityKind {
    var systemImage: String {
        switch self {
        case .session: "circle.dotted"
        case .bluetooth: "dot.radiowaves.left.and.right"
        case .lock: "lock.fill"
        case .returnState: "arrow.uturn.backward.circle"
        case .error: "exclamationmark.triangle.fill"
        }
    }
}
