import Testing
@testable import PresenceCore

struct PresenceEngineTests {
    @Test func testIdleDepartureWaitsForGraceAndEmitsStableAway() {
        var engine = PresenceEngine()
        #expect(engine.update(.init(time: 0, idleSeconds: 299)) == .present)
        #expect(engine.update(.init(time: 1, idleSeconds: 300)) == .leaving)
        #expect(engine.update(.init(time: 15, idleSeconds: 314)) == .leaving)
        #expect(engine.update(.init(time: 16, idleSeconds: 315)) == .away)
        #expect(engine.update(.init(time: 100, idleSeconds: 399)) == .away)
    }

    @Test func testTypingVetoesFarDeviceAndCancelsDeparture() {
        var engine = PresenceEngine(policy: .init(useBluetooth: true))
        #expect(engine.update(.init(time: 0, idleSeconds: 45, proximity: .far)) == .leaving)
        #expect(engine.update(.init(time: 14, idleSeconds: 0, proximity: .far)) == .present)
        #expect(engine.update(.init(time: 44, idleSeconds: 30, proximity: .far)) == .leaving)
        #expect(engine.update(.init(time: 58, idleSeconds: 44, proximity: .far)) == .leaving)
        #expect(engine.update(.init(time: 59, idleSeconds: 45, proximity: .far)) == .away)
    }

    @Test func testUnavailableBluetoothUsesLongerIdleFallback() {
        for signal in [Proximity.unknown, .unavailable] {
            var engine = PresenceEngine(policy: .init(useBluetooth: true))
            #expect(engine.update(.init(time: 0, idleSeconds: 90, proximity: signal)) == .present)
            #expect(engine.update(.init(time: 1, idleSeconds: 300, proximity: signal)) == .leaving)
        }
    }

    @Test func testPhoneLeftOnDeskDoesNotDisableIdleLock() {
        var engine = PresenceEngine(policy: .init(useBluetooth: true))
        #expect(engine.update(.init(time: 0, idleSeconds: 300, proximity: .near)) == .leaving)
        #expect(engine.update(.init(time: 15, idleSeconds: 315, proximity: .near)) == .away)
    }

    @Test func testInactiveSessionAndBadSensorDataCannotInferPresence() {
        var engine = PresenceEngine()
        #expect(engine.update(.init(time: 0, idleSeconds: 0, sessionAvailable: false)) == .suspended)
        for value in [Double.nan, Double.infinity, -1] {
            #expect(engine.update(.init(time: 1, idleSeconds: value)) == .unknown)
        }
        #expect(engine.update(.init(time: 1, idleSeconds: nil)) == .unknown)
    }

    @Test func testSleepAndResetDiscardDepartureCountdown() {
        var engine = PresenceEngine()
        #expect(engine.update(.init(time: 0, idleSeconds: 400)) == .leaving)
        #expect(engine.update(.init(time: 5, idleSeconds: 405, sessionAvailable: false)) == .suspended)
        #expect(engine.update(.init(time: 100, idleSeconds: 500)) == .leaving)
        engine.reset()
        #expect(engine.update(.init(time: 110, idleSeconds: 510)) == .leaving)
    }
}
