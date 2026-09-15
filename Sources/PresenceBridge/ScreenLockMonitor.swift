import CoreGraphics
import PresenceCore

/// Public session query, but an undocumented dictionary key: treat as a compatibility signal.
/// Never expose the rest of the session dictionary (it can contain user-identifying fields).
struct ScreenLockMonitor {
    private var tracker = ScreenLockTracker()

    mutating func read(session: [String: Any]?, sessionAvailable: Bool) -> ScreenLockState {
        guard let session else { return .unknown }
        let observation: LockFlagObservation
        if let raw = session["CGSSessionScreenIsLocked"] {
            if let locked = raw as? Bool { observation = locked ? .locked : .unlocked }
            else { observation = .invalid }
        } else { observation = .missing }
        return tracker.observe(observation, sessionAvailable: sessionAvailable)
    }
}
