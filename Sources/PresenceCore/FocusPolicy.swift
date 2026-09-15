import Foundation

public enum FocusAction: String, Sendable, CaseIterable { case enable, renew, disable }

/// A single in-flight action; manual overrides suppress reacquisition until a new work session.
public struct FocusPolicy: Sendable {
    public private(set) var mayOwnFocus = false
    public private(set) var suppressed = false
    public private(set) var inFlight: FocusAction?
    private var lastRenewal: TimeInterval = -.infinity
    private var retryAfter: TimeInterval = 0

    public init() {}

    public mutating func beginWorkSession() { suppressed = false; retryAfter = 0 }

    public mutating func next(wantsFocus: Bool, at time: TimeInterval) -> FocusAction? {
        guard inFlight == nil, time >= retryAfter else { return nil }
        let action: FocusAction?
        if !wantsFocus {
            action = mayOwnFocus ? .disable : nil
        } else if suppressed {
            action = nil
        } else if !mayOwnFocus {
            action = .enable
        } else {
            action = time - lastRenewal >= 300 ? .renew : nil
        }
        inFlight = action
        // A timeout may happen after the shortcut changed Focus. Retain cleanup responsibility.
        if action == .enable { mayOwnFocus = true }
        return action
    }

    public mutating func complete(_ action: FocusAction, output: String?, at time: TimeInterval) {
        guard action == inFlight else { return }
        inFlight = nil
        let expected = action == .disable ? "disabled" : (action == .enable ? "enabled" : "renewed")
        if output == expected {
            mayOwnFocus = action != .disable
            lastRenewal = time
            retryAfter = 0
        } else if output == "skipped" {
            mayOwnFocus = false
            suppressed = true
        } else {
            // Never retry ON/renew blindly after ambiguous failure. OFF can retry at a bounded rate.
            if action != .disable { suppressed = true }
            retryAfter = time + 30
        }
    }
}
