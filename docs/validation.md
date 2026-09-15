# Validation record

## Initial local environment

- 2026-09-15: Apple Silicon, macOS 27.0, Swift 6.4, Command Line Tools.
- Debug build: passed.
- `bash scripts/test.sh`: **25 tests passed** across four Swift Testing suites. The local tools omit XCTest; the project uses the bundled Swift Testing runtime instead. Repeated builds exposed an intermittent macro-discovery issue; the helper explicitly loads the installed Testing plugin for this Command Line Tools layout.
- Release bundle: built and ad-hoc signature verified. Effect-free packaged executable check: passed.
- Updated control panel: native UI inspection passed for startup, Bluetooth toggle, device picker, and refusal to arm proximity locking without a confirmed near device. Lock and Focus effects stayed off.
- Local 40-second Bluetooth scan: passed, including repeated nearby Watch advertisements. Device names/identifiers are intentionally omitted from this public record.
- Active Core Bluetooth connection to an owner-confirmed Apple Watch: passed on this Mac. Repeated connected RSSI callbacks arrived approximately every two seconds, with near-desk readings around −38…−41 dBm. No companion app or private Bluetooth database was used.
- Owner-requested walk test: connection remained alive while RSSI moved from roughly −37…−45 dBm near the desk to −66…−70 dBm farther away, then recovered. The initial generic −78 dBm leave threshold did not classify this movement as away. This demonstrates why desk calibration is required; it is not a passed auto-lock test.
- The owner confirmed walking away and returning with the Watch screen dark. The app subsequently showed Away at approximately −86…−87 dBm and Near again around −44 dBm while the active connection continued. Presence-state transitions are validated on this setup; they do not prove that the Mac locked.
- Desk calibration completed at approximately −60 dBm for the leave threshold. Actual locking is pending macOS Accessibility permission and the final lock test. No lock or Focus actions ran during observation.
- macOS 13 is the deployment target; older OS/device combinations have not yet been field-tested.

## Automated coverage

The test suite covers departure grace, cancellation by input, unavailable-radio fallback, a phone left near the Mac, invalid input data, sleep/reset, RSSI smoothing/staleness, serialized Focus actions, renewal cadence, manual overrides, ambiguous outcomes, and cleanup backoff. Added coverage checks the near-before-arm gate, invalid signal rejection, repeated radio-loss notifications, stale data after radio recovery, the faster departure timing, and return during the grace period.

CI intentionally does not post lock events, request Bluetooth/Accessibility permissions, or run Focus shortcuts. A build is not proof of real-device automation reliability.

## Required manual checks before daily use

| Scenario | Expected result | Initial status |
|---|---|---|
| Fresh launch | Observation only; no Bluetooth prompt or effects | Passed (updated control panel) |
| Watch walk-away and return | Active signal persists; Away then Near | Passed on one owner-confirmed Watch/Mac setup; lock effect pending |
| Idle departure | Countdown after threshold; one lock request if enabled | Pending |
| Typing while beacon is far | No departure within activity veto | Policy tests passed |
| Phone/beacon stays on desk | Idle timeout still applies | Pending |
| Lock now / automatic lock | Mac visibly locked; authentication required | Pending |
| Accessibility denied/revoked | Visible failure, no false “locked” claim | Pending |
| Sleep/wake, lid close, session switching | Focus cleanup attempted; return confirmation required | Pending |
| Manual lock with display awake | Document detection delay; no claim of full lock observation | Pending |
| Bluetooth off/denied/device never seen | Cannot arm device locking; established-session radio loss expires to far | Policy tests passed; physical radio test pending |
| Shared Focus On/Renew/Off | Mac and iPhone match expected policy; local receipts correct | Pending |
| Another Focus active | Recipes preserve it | Pending |
| User manually disables At Mac | Renew skips and suppresses reacquisition | Pending |
| Quit/crash/offline iPhone | Cleanup or finite expiry; document sync latency | Pending |
| Login item | One instance; starts observing | Pending |

Record device models, OS builds, selected sensor type, observed timing, and results in the associated issue. Redact peripheral identifiers and private notification contents.
