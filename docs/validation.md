# Validation record

## Initial local environment

- 2026-09-15: Apple Silicon, macOS 27.0, Swift 6.4, Command Line Tools.
- Debug build: passed.
- `swift test --disable-xctest`: **17 tests passed** across three Swift Testing suites. The local tools omit XCTest; the project uses the bundled Swift Testing runtime instead.
- Release bundle: built and ad-hoc signature verified. Effect-free packaged executable check: passed.
- GUI process launches and stays running. Automated UI inspection timed out, so visual interaction is not marked passed.
- macOS 13 is the deployment target; older OS/device combinations have not yet been field-tested.

## Automated coverage

The test suite covers departure grace, cancellation by input, unavailable-radio fallback, a phone left near the Mac, invalid input data, sleep/reset, RSSI smoothing/staleness, serialized Focus actions, renewal cadence, manual overrides, ambiguous outcomes, and cleanup backoff.

CI intentionally does not post lock events, request Bluetooth/Accessibility permissions, or run Focus shortcuts. A build is not proof of real-device automation reliability.

## Required manual checks before daily use

| Scenario | Expected result | Initial status |
|---|---|---|
| Fresh launch | Observation only; no Bluetooth prompt or effects | Process launch passed; visual check pending |
| Idle departure | Countdown after threshold; one lock request if enabled | Pending |
| Typing while beacon is far | No departure within activity veto | Pending |
| Phone/beacon stays on desk | Idle timeout still applies | Pending |
| Lock now / automatic lock | Mac visibly locked; authentication required | Pending |
| Accessibility denied/revoked | Visible failure, no false “locked” claim | Pending |
| Sleep/wake, lid close, session switching | Focus cleanup attempted; return confirmation required | Pending |
| Manual lock with display awake | Document detection delay; no claim of full lock observation | Pending |
| Bluetooth off/denied/device never seen | Ordinary idle fallback | Pending |
| Shared Focus On/Renew/Off | Mac and iPhone match expected policy; local receipts correct | Pending |
| Another Focus active | Recipes preserve it | Pending |
| User manually disables At Mac | Renew skips and suppresses reacquisition | Pending |
| Quit/crash/offline iPhone | Cleanup or finite expiry; document sync latency | Pending |
| Login item | One instance; starts observing | Pending |

Record device models, OS builds, selected sensor type, observed timing, and results in the associated issue. Redact peripheral identifiers and private notification contents.
