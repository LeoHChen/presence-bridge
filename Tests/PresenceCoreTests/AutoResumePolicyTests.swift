import Testing
@testable import PresenceCore

struct AutoResumePolicyTests {
    private func sample(_ policy: inout AutoResumePolicy, _ time: Double,
                        _ state: ScreenLockState, waiting: Bool = true,
                        enabled: Bool = true, available: Bool = true, near: Bool = true) -> Bool {
        policy.update(at: time, waiting: waiting, enabled: enabled, lockState: state,
                      sessionAvailable: available, deviceReady: near)
    }

    @Test func resumeOnceAfterLockUnlockAndStableNear() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked))
        #expect(!sample(&policy, 10, .unlocked))
        #expect(!sample(&policy, 11, .unlocked))
        #expect(sample(&policy, 12, .unlocked))
        #expect(!sample(&policy, 20, .unlocked))
    }

    @Test func wakeOrPostedLockShortcutAloneCannotResume() {
        var policy = AutoResumePolicy()
        for time in [0.0, 10, 30] { #expect(!sample(&policy, time, .unlocked)) }
    }

    @Test func anotherDepartureRequiresAnotherObservedLockCycle() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked))
        #expect(!sample(&policy, 10, .unlocked))
        #expect(sample(&policy, 12, .unlocked))
        #expect(!sample(&policy, 20, .unlocked))
        #expect(!sample(&policy, 22, .unlocked))
        #expect(!sample(&policy, 30, .locked))
        #expect(!sample(&policy, 40, .unlocked))
        #expect(sample(&policy, 42, .unlocked))
    }

    @Test func waitForWatchReconnectionAfterUnlock() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked))
        #expect(!sample(&policy, 10, .unlocked, near: false))
        #expect(!sample(&policy, 30, .unlocked, near: false))
        #expect(!sample(&policy, 40, .unlocked))
        #expect(sample(&policy, 42, .unlocked))
    }

    @Test func pauseOrFreshLaunchCannotResume() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked))
        #expect(!sample(&policy, 10, .unlocked, waiting: false))
        #expect(!sample(&policy, 20, .unlocked))
        #expect(!sample(&policy, 30, .unlocked))
    }

    @Test func lockScreenInputAndNearWatchDoNotResume() {
        var policy = AutoResumePolicy()
        for time in [0.0, 10, 30] { #expect(!sample(&policy, time, .locked)) }
    }

    @Test func disabledAutoResumeStaysWaiting() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked, enabled: false))
        #expect(!sample(&policy, 10, .unlocked, enabled: false))
        #expect(!sample(&policy, 30, .unlocked, enabled: false))
    }

    @Test func uncertaintyOrSignalLossRestartsSettlePeriod() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked))
        #expect(!sample(&policy, 10, .unlocked))
        #expect(!sample(&policy, 11, .unknown))
        #expect(!sample(&policy, 12, .unlocked))
        #expect(!sample(&policy, 13, .unlocked, near: false))
        #expect(!sample(&policy, 14, .unlocked))
        #expect(sample(&policy, 16, .unlocked))
    }

    @Test func sessionSwitchCannotResumeUntilAvailable() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 0, .locked))
        #expect(!sample(&policy, 10, .unlocked, available: false))
        #expect(!sample(&policy, 20, .unlocked, available: false))
        #expect(!sample(&policy, 30, .unlocked))
        #expect(sample(&policy, 32, .unlocked))
    }

    @Test func invalidClockCannotResume() {
        var policy = AutoResumePolicy()
        #expect(!sample(&policy, 10, .locked))
        #expect(!sample(&policy, 20, .unlocked))
        #expect(!sample(&policy, 19, .unlocked))
        #expect(!sample(&policy, .nan, .unlocked))
        #expect(!sample(&policy, 30, .unlocked))
    }

    @Test func missingLockFlagRequiresObservedLockedFlag() {
        var tracker = ScreenLockTracker()
        #expect(tracker.observe(.missing, sessionAvailable: true) == .unknown)
        #expect(tracker.observe(.locked, sessionAvailable: true) == .locked)
        #expect(tracker.observe(.missing, sessionAvailable: true) == .unlocked)
        #expect(tracker.observe(.invalid, sessionAvailable: true) == .unknown)
        #expect(tracker.observe(.missing, sessionAvailable: false) == .unknown)
    }
}
