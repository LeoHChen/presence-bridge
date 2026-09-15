# Changelog

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
