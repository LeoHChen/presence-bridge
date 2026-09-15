import Testing
@testable import PresenceCore

struct ProximityFilterTests {
    @Test func testNeedsThreeSamplesAndIgnoresInvalidRSSI() {
        var filter = ProximityFilter()
        filter.observe(rssi: 127, at: 0)
        #expect(filter.proximity(at: 50, radioAvailable: true) == .unknown)
        filter.observe(rssi: -50, at: 50)
        filter.observe(rssi: -50, at: 51)
        #expect(filter.proximity(at: 51, radioAvailable: true) == .unknown)
        filter.observe(rssi: -50, at: 52)
        #expect(filter.proximity(at: 52, radioAvailable: true) == .near)
    }

    @Test func testRadioLossIsUnknownAvailabilityNotDepartureEvidence() {
        var filter = ProximityFilter()
        filter.observe(rssi: -50, at: 0)
        #expect(filter.proximity(at: 20, radioAvailable: false) == .unavailable)
        #expect(filter.proximity(at: 20, radioAvailable: true) == .far)
    }

    @Test func testOneWeakPacketCannotFlipNearToFar() {
        var filter = ProximityFilter()
        for time in 0...2 { filter.observe(rssi: -50, at: Double(time)) }
        filter.observe(rssi: -100, at: 3)
        #expect(filter.proximity(at: 3, radioAvailable: true) == .near)
    }

    @Test func testReappearanceRequiresFreshCalibrationSamples() {
        var filter = ProximityFilter()
        for time in 0...2 { filter.observe(rssi: -50, at: Double(time)) }
        #expect(filter.proximity(at: 20, radioAvailable: true) == .far)
        filter.observe(rssi: -50, at: 21)
        #expect(filter.proximity(at: 21, radioAvailable: true) == .unknown)
        filter.observe(rssi: -50, at: 22)
        filter.observe(rssi: -50, at: 23)
        #expect(filter.proximity(at: 23, radioAvailable: true) == .near)
    }
}
