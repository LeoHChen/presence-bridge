import ApplicationServices

enum ScreenLocker {
    static var authorized: Bool { AXIsProcessTrusted() }

    static func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Posts Apple's documented Control-Command-Q shortcut. This is a request, not lock confirmation.
    static func requestLock() -> Bool {
        guard authorized,
              let down = CGEvent(keyboardEventSource: nil, virtualKey: 12, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 12, keyDown: false) else { return false }
        down.flags = [.maskControl, .maskCommand]
        up.flags = [.maskControl, .maskCommand]
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }
}
