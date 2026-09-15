import Testing
@testable import PresenceCore

struct DevicePresenceTests {
    private func nearbyDevice() -> DevicePresence {
        var device = DevicePresence()
        device.setRadioAvailable(true, at: 0)
        for time in [0.0, 2.0, 4.0] { device.observe(rssi: -50, at: time) }
        return device
    }

    @Test func cannotArmWithoutFreshNearSamples() {
        var device = DevicePresence()
        #expect(!device.readyToArm(at: 0))
        device.setRadioAvailable(true, at: 0)
        device.observe(rssi: -50, at: 0)
        #expect(!device.readyToArm(at: 1))
        device.observe(rssi: -50, at: 2)
        device.observe(rssi: -50, at: 4)
        #expect(device.readyToArm(at: 4))
        #expect(!device.readyToArm(at: 13))
    }

    @Test func prolongedRadioLossAfterEstablishmentMeansDeparture() {
        var device = nearbyDevice()
        device.setRadioAvailable(false, at: 5)
        #expect(device.proximity(at: 12) == .unavailable)
        #expect(device.proximity(at: 13) == .far)
        #expect(!device.readyToArm(at: 13))
    }

    @Test func repeatedRadioLossNotificationsCannotRestartTimeout() {
        var device = nearbyDevice()
        device.setRadioAvailable(false, at: 5)
        device.setRadioAvailable(false, at: 11)
        #expect(device.proximity(at: 13) == .far)
    }

    @Test func RadioFailureBeforeSeeingNearDoesNotInventDeparture() {
        var device = DevicePresence()
        device.setRadioAvailable(false, at: 0)
        #expect(device.proximity(at: 100) == .unavailable)
        #expect(!device.readyToArm(at: 100))
    }

    @Test func radioRecoveryDoesNotMakeOldSignalFresh() {
        var device = nearbyDevice()
        device.setRadioAvailable(false, at: 5)
        device.setRadioAvailable(true, at: 20)
        #expect(device.proximity(at: 20) == .far)
        device.observe(rssi: -50, at: 20)
        #expect(!device.readyToArm(at: 20))
        device.observe(rssi: -50, at: 22)
        device.observe(rssi: -50, at: 24)
        #expect(device.readyToArm(at: 24))
    }

    @Test func signalLossReachesAwayWithFastPolicyWithoutMinutesOfIdle() {
        let device = nearbyDevice()
        var engine = PresenceEngine(policy: .init(departureGrace: 8, activityVeto: 5, useBluetooth: true))
        #expect(engine.update(.init(time: 4, idleSeconds: 0, proximity: device.proximity(at: 4))) == .present)
        #expect(engine.update(.init(time: 13, idleSeconds: 9, proximity: device.proximity(at: 13))) == .leaving)
        #expect(engine.update(.init(time: 20, idleSeconds: 16, proximity: device.proximity(at: 20))) == .leaving)
        #expect(engine.update(.init(time: 21, idleSeconds: 17, proximity: device.proximity(at: 21))) == .away)
    }

    @Test func walkingBackDuringGraceCancelsDeparture() {
        var device = nearbyDevice()
        var engine = PresenceEngine(policy: .init(departureGrace: 8, activityVeto: 5, useBluetooth: true))
        #expect(engine.update(.init(time: 13, idleSeconds: 20, proximity: device.proximity(at: 13))) == .leaving)
        for time in [14.0, 16.0, 18.0] { device.observe(rssi: -50, at: time) }
        #expect(engine.update(.init(time: 18, idleSeconds: 25, proximity: device.proximity(at: 18))) == .present)
    }

    @Test func invalidSamplesDoNotKeepDeviceAlive() {
        var device = nearbyDevice()
        device.observe(rssi: 127, at: 10)
        device.observe(rssi: 0, at: 11)
        device.observe(rssi: -50, at: .nan)
        #expect(device.sampleCount == 3)
        #expect(device.proximity(at: 13) == .far)
    }
}
