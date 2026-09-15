import Foundation

/// RSSI is a noisy hint, not a distance measurement or proof of identity.
public struct ProximityFilter: Sendable {
    public private(set) var smoothedRSSI: Double?
    private var lastSeen: TimeInterval?
    private var stable: Proximity = .unknown
    private var candidate: Proximity = .unknown
    private var consecutive = 0
    public let nearThreshold: Double
    public let farThreshold: Double
    public let staleAfter: TimeInterval

    public init(nearThreshold: Double = -65, farThreshold: Double = -78,
                staleAfter: TimeInterval = 12) {
        self.nearThreshold = nearThreshold
        self.farThreshold = min(farThreshold, nearThreshold - 1)
        self.staleAfter = max(5, staleAfter)
    }

    public mutating func observe(rssi: Int, at time: TimeInterval) {
        // 127 denotes an unavailable RSSI; positive values are unusable here.
        guard (-127 ... -1).contains(rssi), time.isFinite else { return }
        if let previous = lastSeen, time - previous > staleAfter {
            smoothedRSSI = nil
            stable = .unknown
            consecutive = 0
        }
        lastSeen = time
        let value = smoothedRSSI.map { 0.3 * Double(rssi) + 0.7 * $0 } ?? Double(rssi)
        smoothedRSSI = value
        let next: Proximity = value >= nearThreshold ? .near : (value <= farThreshold ? .far : .unknown)
        guard next != .unknown else { consecutive = 0; return }
        consecutive = next == candidate ? consecutive + 1 : 1
        candidate = next
        if consecutive >= 3 { stable = next }
    }

    public func proximity(at time: TimeInterval, radioAvailable: Bool) -> Proximity {
        guard radioAvailable else { return .unavailable }
        guard let lastSeen else { return .unknown }
        // Only a device actually observed during this scan can time out to far.
        if time - lastSeen > staleAfter { return .far }
        return stable
    }
}
