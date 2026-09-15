import Foundation
import Darwin
import PresenceCore

/// Runs fixed shortcut names directly, with no shell interpolation or network transport.
@MainActor
final class ShortcutRunner {
    struct Result {
        var output: String?
        var message: String
    }

    private let names: [FocusAction: String] = [
        .enable: "Presence Bridge — Focus On",
        .renew: "Presence Bridge — Focus Renew",
        .disable: "Presence Bridge — Focus Off"
    ]

    func run(_ action: FocusAction) async -> Result {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("presence-bridge-\(UUID().uuidString)", isDirectory: true)
        let outputURL = directory.appendingPathComponent("result.txt")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
        } catch {
            return Result(output: nil, message: "Cannot create private shortcut output directory")
        }
        defer { try? FileManager.default.removeItem(at: directory) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["run", names[action]!, "--output-path", outputURL.path]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch {
            return Result(output: nil, message: "Cannot start Shortcuts; check installation")
        }

        let deadline = ProcessInfo.processInfo.systemUptime + 20
        while process.isRunning, ProcessInfo.processInfo.systemUptime < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        if process.isRunning {
            process.terminate()
            let killDeadline = ProcessInfo.processInfo.systemUptime + 2
            while process.isRunning, ProcessInfo.processInfo.systemUptime < killDeadline {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            // The Shortcuts service may already have performed an effect. The Focus lease is the fallback.
            return Result(output: nil, message: "Shortcut timed out; Focus outcome is unknown")
        }
        guard process.terminationStatus == 0 else {
            return Result(output: nil, message: "Shortcut failed; check its name and run it manually")
        }
        guard let handle = try? FileHandle(forReadingFrom: outputURL) else {
            return Result(output: nil, message: "Shortcut returned no receipt; check Stop and Output")
        }
        defer { try? handle.close() }
        let data = (try? handle.read(upToCount: 128)) ?? Data()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let expected = action == .enable ? "enabled" : action == .renew ? "renewed" : "disabled"
        guard output == expected || output == "skipped" else {
            return Result(output: nil, message: "Unexpected shortcut receipt; review the setup guide")
        }
        return Result(output: output, message: "Focus \(action.rawValue): \(output!) (local receipt)")
    }
}
