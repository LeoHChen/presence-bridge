# Validation record

## Unreleased automatic return

The return policy and lock-field interpretation add 11 tests for lock/unlock cycles, repeated departures, delayed Watch recovery, pause/restart, disabled automatic return, unknown observations, and invalid clocks. These exercise decisions without locking the machine. An unlocked-session probe on the local Mac confirms the lock field is absent, so the adapter correctly starts with unknown status. End-to-end automatic return and a second real departure are still pending; the v0.1.0 physical test below validated departure locking only.

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
- Desk calibration completed at approximately −60 dBm for the leave threshold. No lock or Focus actions ran during observation.
- Initial **Lock now** attempt: the app correctly reported missing Accessibility permission and did not post a lock event. The macOS 27 permission page (Device Control and Data Access) showed an enabled entry, but restarting the current local bundle did not resolve the discrepancy. With the owner's approval and OS authentication, removing the old entry, adding the exact current bundle while it was closed, and reopening it restored permission. Adding over the existing entry alone was insufficient.
- **Lock now** passed after permission repair: the owner confirmed the Mac locked and they unlocked normally. The app required **I’m back** before resuming effects.
- Automatic Watch departure test: with the selected Watch near, lock effects enabled, and a calibrated −59 dBm departure threshold, the app was armed for a screen-dark walk into another room. On return, the owner reported that it seemed to be working, and the app showed **Lock requested; use I’m back after unlocking** with a near Watch signal. Record this as an owner-reported successful automatic lock on one setup, not a measured latency/reliability benchmark. No Focus action was enabled.
- macOS 13 is the deployment target; older OS/device combinations have not yet been field-tested.

## First preview package

- The universal package builds both arm64 and x86_64. Each Mach-O slice declares macOS 13.0 as its minimum OS.
- Local archive extraction, ad-hoc code signature verification, and the Apple Silicon executable self-check passed. The archive includes only the app, MIT license, installation guide, and source-revision build information; device settings and diagnostic output are excluded.
- SHA-256 verification passes for the ZIP, installation guide, and build information. CI builds the same package recipe and retains the result for release publication after a successful main-branch run.
- Intel compilation is checked, but physical Watch/Focus behavior on Intel and older macOS versions remains untested. No Developer ID certificate or notarization is included in v0.1.0.

## Automated coverage

The test suite covers departure grace, cancellation by input, unavailable-radio fallback, a phone left near the Mac, invalid input data, sleep/reset, RSSI smoothing/staleness, serialized Focus actions, renewal cadence, manual overrides, ambiguous outcomes, and cleanup backoff. Added coverage checks the near-before-arm gate, invalid signal rejection, repeated radio-loss notifications, stale data after radio recovery, the faster departure timing, and return during the grace period.

CI intentionally does not post lock events, request Bluetooth/Accessibility permissions, or run Focus shortcuts. A build is not proof of real-device automation reliability.

## Required manual checks before daily use

| Scenario | Expected result | Initial status |
|---|---|---|
| Fresh launch | Observation only; no Bluetooth prompt or effects | Passed (updated control panel) |
| Watch walk-away and return | Active signal persists; Away then Near | Passed on one owner-confirmed Watch/Mac setup; automatic lock reported working |
| Idle departure | Countdown after threshold; one lock request if enabled | Pending |
| Typing while beacon is far | No departure within activity veto | Policy tests passed |
| Phone/beacon stays on desk | Idle timeout still applies | Pending |
| Lock now / automatic lock | Mac visibly locked; authentication required | Lock now confirmed; automatic Watch test reported working by owner, with lock request observed in app |
| Accessibility denied/revoked | Visible failure, no false “locked” claim | Passed for an untrusted running app despite an enabled Settings entry; live revocation remains pending |
| Sleep/wake, lid close, session switching | Focus cleanup attempted; return confirmation required | Pending |
| Manual lock with display awake | Document detection delay; no claim of full lock observation | Pending |
| Bluetooth off/denied/device never seen | Cannot arm device locking; established-session radio loss expires to far | Policy tests passed; physical radio test pending |
| Shared Focus On/Renew/Off | Mac and iPhone match expected policy; local receipts correct | Pending |
| Another Focus active | Recipes preserve it | Pending |
| User manually disables At Mac | Renew skips and suppresses reacquisition | Pending |
| Quit/crash/offline iPhone | Cleanup or finite expiry; document sync latency | Pending |
| Login item | One instance; starts observing | Pending |

Record device models, OS builds, selected sensor type, observed timing, and results in the associated issue. Redact peripheral identifiers and private notification contents.
