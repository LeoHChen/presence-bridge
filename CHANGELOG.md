# Changelog

## Unreleased — 0.2.0

- Add an original lock-and-proximity app icon and bundle it at all standard macOS icon sizes.
- Filter blank, placeholder, UUID-like, and address-like Bluetooth advertisements from the device picker; sort the selected device first when available.
- Display the selected friendly name and availability in the main panel and menu bar. Persist the UUID and sanitized name, including migration from the earlier UUID-only preference.
- Add a bounded, clearable, session-only activity history for departure, lock request, observed lock, unlock, and automatic resume. The history excludes UUIDs and raw RSSI.
- Replace the duplicated full-panel menu-bar popover with a compact status menu whose Open command activates, deminiaturizes, and brings the control window forward.
- Refresh the control panel hierarchy and labels for the complete test flow.
- Add core policy tests for device-name filtering, selection restoration, activity ordering, retention, and duplicate coalescing.

## 0.1.1 — local test build

- Optimized local application build for full-function testing, with a visible version number, distinct waiting/test status, and **Test detection only** labeling to distinguish simulation from real automatic locking.

- Resume an active work session automatically after observing a lock/unlock cycle, waiting for the selected Bluetooth device to be near and readiness to remain stable for two seconds.
- Add **Resume after unlocking** (on by default). Pause and fresh launches remain inactive. Manual **I'm back** remains available when return detection is unavailable.
- Observe an undocumented lock-state field through the public Core Graphics session query. Require an actual locked observation before accepting its disappearance as unlocked; screen wake or recent input alone cannot resume a session.
- Preserve manual Focus overrides across automatic returns. Full lock/unlock and next-departure hardware testing is still required before release.

## 0.1.0 — 2026-09-15

First public preview of Presence Bridge, a native macOS menu bar app for Watch/iPhone-assisted departure locking and optional shared Focus shortcuts.

### Included

- Active Core Bluetooth connection and signal polling for one selected device, reconnection, and passive advertisement fallback.
- Desk calibration, signal smoothing, freshness checks, and a walk test with no lock/Focus effects.
- Automatic lock requests after departure, with an activity veto and grace period; independent idle timeout fallback.
- Observation on launch, explicit arming, pause, and return confirmation. The app never unlocks the Mac.
- User-created Shortcuts integration for shared At Mac Focus, finite leases, and serialized effects.
- SwiftUI control panel, menu bar, optional login item, source build scripts, and 25 policy tests.
- Universal Mac ZIP, MIT license, installation guide, source-revision build information, and SHA-256 checksums.

### Validation and limitations

- An owner-confirmed Apple Watch stayed connected with its screen dark during walking away and returning. The owner reported the automatic lock test working; the app showed a lock request and required return confirmation. One Apple Silicon/macOS 27 setup tested, without a measured lock-latency benchmark.
- The explicit Lock now action visibly locked the Mac, confirmed by the owner.
- Apple Watch Auto Unlock proximity/authentication is not exposed here; this uses ordinary public Core Bluetooth signals. Device compatibility and signal stability vary.
- Preview downloads are ad-hoc signed and not notarized. Intel hardware and older macOS versions need field validation.
- Focus recipes need user setup and real-device validation. Shared Focus affects both Mac and iPhone; iPhone-only notification suppression is not implemented.
- Calibration and effect toggles reset each launch. Returning after a lock requires normal unlocking and **I'm back**.
