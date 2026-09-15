import Testing
@testable import PresenceCore

struct FocusPolicyTests {
    @Test func testSerializesOnThenOffWhenUserLeavesDuringOn() {
        var policy = FocusPolicy()
        #expect(policy.next(wantsFocus: true, at: 0) == .enable)
        #expect(policy.next(wantsFocus: false, at: 1) == nil)
        policy.complete(.enable, output: "enabled", at: 2)
        #expect(policy.next(wantsFocus: false, at: 2) == .disable)
        policy.complete(.disable, output: "disabled", at: 3)
        #expect(!(policy.mayOwnFocus))
        #expect(policy.next(wantsFocus: false, at: 4) == nil)
    }

    @Test func testRenewalIsRateLimited() {
        var policy = FocusPolicy()
        #expect(policy.next(wantsFocus: true, at: 0) == .enable)
        policy.complete(.enable, output: "enabled", at: 1)
        #expect(policy.next(wantsFocus: true, at: 300) == nil)
        #expect(policy.next(wantsFocus: true, at: 301) == .renew)
    }

    @Test func testManualOverridePreventsReacquisitionUntilExplicitSession() {
        var policy = FocusPolicy()
        _ = policy.next(wantsFocus: true, at: 0)
        policy.complete(.enable, output: "enabled", at: 1)
        _ = policy.next(wantsFocus: true, at: 301)
        policy.complete(.renew, output: "skipped", at: 302)
        #expect(policy.next(wantsFocus: true, at: 900) == nil)
        #expect(policy.next(wantsFocus: false, at: 901) == nil)
        policy.beginWorkSession()
        #expect(policy.next(wantsFocus: true, at: 902) == .enable)
    }

    @Test func testAmbiguousEnableDoesNotRetryButStillCleansUp() {
        var policy = FocusPolicy()
        _ = policy.next(wantsFocus: true, at: 0)
        policy.complete(.enable, output: nil, at: 20)
        #expect(policy.mayOwnFocus)
        #expect(policy.next(wantsFocus: true, at: 50) == nil)
        #expect(policy.next(wantsFocus: false, at: 50) == .disable)
    }

    @Test func testFailedCleanupHasBackoffAndCanRetry() {
        var policy = FocusPolicy()
        _ = policy.next(wantsFocus: true, at: 0)
        policy.complete(.enable, output: "enabled", at: 1)
        _ = policy.next(wantsFocus: false, at: 2)
        policy.complete(.disable, output: nil, at: 3)
        #expect(policy.next(wantsFocus: false, at: 32) == nil)
        #expect(policy.next(wantsFocus: false, at: 33) == .disable)
    }

    @Test func testOtherFocusIsNotOwnedWhenOnIsSkipped() {
        var policy = FocusPolicy()
        _ = policy.next(wantsFocus: true, at: 0)
        policy.complete(.enable, output: "skipped", at: 1)
        #expect(!(policy.mayOwnFocus))
        #expect(policy.next(wantsFocus: false, at: 2) == nil)
    }

    @Test func testUnexpectedReceiptIsAnAmbiguousFailure() {
        var policy = FocusPolicy()
        _ = policy.next(wantsFocus: true, at: 0)
        policy.complete(.enable, output: "disabled", at: 1)
        #expect(policy.suppressed)
        #expect(policy.mayOwnFocus)
    }
}
