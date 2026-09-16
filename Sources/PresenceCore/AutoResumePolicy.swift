import Foundation

public enum ScreenLockState: Sendable { case locked, unlocked, unknown }
public enum LockFlagObservation: Sendable { case locked, unlocked, missing, invalid }

/// Interpret an optional compatibility flag without treating its initial absence as an unlock.
public struct ScreenLockTracker: Sendable {
    private var observedLockedFlag = false

    public init() {}

    public mutating func observe(_ flag: LockFlagObservation, sessionAvailable: Bool) -> ScreenLockState {
        guard sessionAvailable else { return .unknown }
        switch flag {
        case .locked:
            observedLockedFlag = true
            return .locked
        case .unlocked:
            return .unlocked
        case .missing:
            // macOS normally removes the flag on unlock. Require seeing it locked first.
            return observedLockedFlag ? .unlocked : .unknown
        case .invalid:
            return .unknown
        }
    }
}

/// Resume only a waiting, armed session after an observed lock/unlock cycle and stable readiness.
public struct AutoResumePolicy: Sendable {
    private var observedLock = false
    private var readySince: TimeInterval?
    private var lastTime: TimeInterval?
    public let settleTime: TimeInterval

    public init(settleTime: TimeInterval = 2) {
        self.settleTime = settleTime.isFinite ? max(1, settleTime) : 2
    }

    public mutating func reset() {
        observedLock = false
        readySince = nil
        lastTime = nil
    }

    public mutating func update(at time: TimeInterval, waiting: Bool, enabled: Bool,
                                lockState: ScreenLockState, sessionAvailable: Bool,
                                deviceReady: Bool) -> Bool {
        guard waiting, time.isFinite, lastTime.map({ time >= $0 }) ?? true else {
            reset()
            return false
        }
        lastTime = time
        if lockState == .locked { observedLock = true }
        guard enabled, observedLock, lockState == .unlocked, sessionAvailable, deviceReady else {
            readySince = nil
            return false
        }
        if readySince == nil { readySince = time }
        guard time - (readySince ?? time) >= settleTime else { return false }
        reset()
        return true
    }
}
