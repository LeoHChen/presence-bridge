# Security and privacy

Presence Bridge is experimental convenience automation. Keep macOS's own automatic lock and password requirements configured. A radio signal, idle counter, or successfully posted key event is not proof that a person left or that the computer is locked.

## Permissions and data

| Capability | Permission / data |
|---|---|
| Idle detection | Public event-age query; no event tap, input content, screenshots, or window-title collection |
| Optional BLE monitoring | Bluetooth permission, requested only when the user enables scanning |
| Lock request | Accessibility for public key-event posting; checked before every request |
| Focus | User-authored Shortcuts and their user-approved permissions; no private Focus preferences or databases |
| Login launch | User-controlled `SMAppService` login item, or optional user LaunchAgent |
| Persistence | Idle threshold and selected peripheral UUID in local app preferences |

Discovered names, signal strength, and state are held in memory; the app writes no telemetry or event history. It caps the device list at 50 and expires old discoveries. The selected UUID is a local identifier and still potentially identifying; do not publish it in bug reports. Shortcut receipts are written briefly to a private temporary directory. A crash can leave receipts until system cleanup. Apple services may handle Focus synchronization and their own logs.

There is no app backend, remote command listener, cloud API key, camera, microphone, location tracking, or root helper. The build has no third-party package dependencies. Active Bluetooth monitoring attempts a connection only to the explicitly selected device. It reads signal strength, not application characteristics, and does not initiate pairing or read private Bluetooth databases. The OS or device may reject a connection. A connection alone is not authenticated ownership. Device identifiers/names are untrusted and are never executed.

## Failure modes and controls

- **False departure:** RSSI can fluctuate, an iPhone can stop advertising, or the user may read without input. The activity veto, smoothing, grace period, desk calibration, effect-free walk test, pause control, and adjustable idle timeout reduce inconvenience; they do not eliminate it.
- **False presence:** A device may be left on the desk or spoofed. The idle timeout still applies even when a beacon is near. Arming a Bluetooth lock session requires a fresh near signal. After establishment, extended signal loss or a disabled Mac radio triggers departure; this can also lock during interference. Disconnections preserve the signal-expiry clock. Bluetooth never grants access or unlocks the Mac.
- **Lock request rejected:** Accessibility can be revoked, key mappings can differ, or event posting may fail to lock. The app reports a request, not verified success. Test the actual password-protected screen before relying on it.
- **Manual lock not observed:** Public screen/session events are incomplete lock-state signals. Some manual locks may only be noticed via idle timeout. Return confirmation prevents automatic resumption after detected departure or sleep.
- **Focus left enabled:** On/Renew recipes must expire after 15 minutes. Cleanup is best-effort and cannot be guaranteed during sleep, crashes, offline sync, or a hung Shortcuts service.
- **Focus conflict:** Recipes guard other named Focus modes, but the check/set pair is not atomic. Manual activation of the same reserved At Mac Focus cannot be distinguished. The app cannot guarantee ownership across devices.
- **Shortcut substitution:** Local users can edit a shortcut with a reserved name to run arbitrary actions. Review those recipes and permissions; this app invokes them with the user's authority. It does not verify their contents.
- **In-flight timeout:** Stopping the local CLI does not necessarily cancel an Apple service action. Effects may complete late. Short recipes, local receipts, serialized execution, and expiry reduce this risk.
- **Login/restart:** Effects and scanning are off each launch. The app does not silently re-arm or claim an existing Focus after a crash.

## Distribution

The script produces an ad-hoc signed local bundle unless `PRESENCE_SIGN_IDENTITY` selects a developer identity. Ad-hoc signing is not notarization or a trust endorsement. Stable Developer ID signing, notarization, a release support matrix, and field testing are required before broader distribution. Never work around installation issues by disabling SIP or Gatekeeper.

## Reporting a vulnerability

Use GitHub's private **Report a vulnerability** option if enabled. Otherwise, open a minimal issue asking for a private reporting channel without exploit details or personal device information. Do not paste credentials, UUIDs, raw advertisements, or private Shortcut contents into public issues. Supported versions: this initial developer branch only; no security response SLA is promised.

The opt-in command-line Bluetooth diagnostic prints nearby device names and signal values locally. No diagnostic is uploaded automatically. Keep this output out of public issues or redact identifying names before sharing.
