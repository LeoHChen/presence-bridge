import Foundation

/// Tracks an established device across radio interruptions without erasing departure evidence.
public struct DevicePresence: Sendable {
    public private(set) var sampleCount = 0
    public private(set) var lastRSSI: Int?
    public private(set) var hasEstablishedNear = false
    public private(set) var radioAvailable = false
    public let farThreshold: Double
    public let signalTimeout: TimeInterval
    private var radioLostAt: TimeInterval?
    private var filter: ProximityFilter

    public init(farThreshold: Double = -78, signalTimeout: TimeInterval = 8) {
        self.farThreshold = min(-45, max(-100, farThreshold))
        self.signalTimeout = max(5, signalTimeout)
        filter = ProximityFilter(nearThreshold: self.farThreshold + 8,
            farThreshold: self.farThreshold, staleAfter: self.signalTimeout)
    }

    public var smoothedRSSI: Double? { filter.smoothedRSSI }

    public mutating func setRadioAvailable(_ available: Bool, at time: TimeInterval) {
        radioAvailable = available
        if available { radioLostAt = nil }
        else if radioLostAt == nil { radioLostAt = time }
    }

    public mutating func observe(rssi: Int, at time: TimeInterval) {
        guard radioAvailable, (-127 ... -1).contains(rssi), time.isFinite else { return }
        filter.observe(rssi: rssi, at: time)
        sampleCount += 1
        lastRSSI = rssi
        if filter.proximity(at: time, radioAvailable: true) == .near { hasEstablishedNear = true }
    }

    public func proximity(at time: TimeInterval) -> Proximity {
        if !radioAvailable {
            if hasEstablishedNear, let lost = radioLostAt, time - lost >= signalTimeout { return .far }
            return .unavailable
        }
        return filter.proximity(at: time, radioAvailable: true)
    }

    public func readyToArm(at time: TimeInterval) -> Bool {
        radioAvailable && hasEstablishedNear && proximity(at: time) == .near
    }
}
