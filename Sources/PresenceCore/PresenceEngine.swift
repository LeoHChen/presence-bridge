import Foundation

public enum Proximity: String, Sendable { case near, far, unknown, unavailable }
public enum PresenceState: String, Sendable { case unknown, present, leaving, away, suspended }

public struct PresencePolicy: Sendable {
    public var idleTimeout: TimeInterval
    public var departureGrace: TimeInterval
    public var activityVeto: TimeInterval
    public var useBluetooth: Bool

    public init(idleTimeout: TimeInterval = 300, departureGrace: TimeInterval = 15,
                activityVeto: TimeInterval = 30, useBluetooth: Bool = false) {
        self.idleTimeout = max(60, idleTimeout)
        self.departureGrace = max(5, departureGrace)
        self.activityVeto = max(5, activityVeto)
        self.useBluetooth = useBluetooth
    }
}

public struct PresenceSample: Sendable {
    /// Monotonic time, never wall-clock time.
    public var time: TimeInterval
    public var idleSeconds: TimeInterval?
    public var proximity: Proximity
    public var sessionAvailable: Bool

    public init(time: TimeInterval, idleSeconds: TimeInterval?, proximity: Proximity = .unknown,
                sessionAvailable: Bool = true) {
        self.time = time
        self.idleSeconds = idleSeconds
        self.proximity = proximity
        self.sessionAvailable = sessionAvailable
    }
}

/// Pure decision engine. Effects and permissions belong to the app layer.
public struct PresenceEngine: Sendable {
    public private(set) var state: PresenceState = .unknown
    private var leavingSince: TimeInterval?
    public var policy: PresencePolicy

    public init(policy: PresencePolicy = .init()) { self.policy = policy }

    public mutating func reset() {
        state = .unknown
        leavingSince = nil
    }

    @discardableResult
    public mutating func update(_ sample: PresenceSample) -> PresenceState {
        guard sample.sessionAvailable else { return set(.suspended) }
        guard let idle = sample.idleSeconds, idle.isFinite, idle >= 0,
              sample.time.isFinite else { return set(.unknown) }

        // Recent input always vetoes an RSSI-based departure.
        let departing: Bool
        if idle < policy.activityVeto {
            departing = false
        } else if policy.useBluetooth, sample.proximity == .near {
            // A phone left on the desk must not defeat the idle timeout forever.
            departing = idle >= policy.idleTimeout
        } else if policy.useBluetooth, sample.proximity == .far {
            departing = true
        } else {
            // No device selected, permission denied, or radio off: ordinary idle fallback.
            departing = idle >= policy.idleTimeout
        }

        guard departing else { return set(.present) }
        if state == .away { return state }
        if leavingSince == nil { leavingSince = sample.time }
        if sample.time - (leavingSince ?? sample.time) >= policy.departureGrace {
            state = .away
        } else {
            state = .leaving
        }
        return state
    }

    private mutating func set(_ next: PresenceState) -> PresenceState {
        state = next
        leavingSince = nil
        return next
    }
}
