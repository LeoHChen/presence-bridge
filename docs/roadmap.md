# Roadmap

This is a sequence of engineering milestones, not a delivery-date commitment. Track execution in [GitHub milestones](https://github.com/LeoHChen/presence-bridge/milestones) and [issues](https://github.com/LeoHChen/presence-bridge/issues).

## v0.1 — Validate the native MVP

Foundation in this initial commit: native menu app, pure policies, test suite, idle fallback, optional BLE scan, opt-in lock request, Shortcuts bridge, build packaging, login item support, documentation and CI.

Remaining exit criteria:

1. **Real-device lock and lifecycle validation:** confirm locking and password protection, manual lock, sleep/wake, screen sleep, fast user switching, permission revocation, and a clear return flow on supported versions. Record false locks and missed locks. Evaluate a more reliable public lock action.
2. **Focus recipes and interoperability:** verify the exact recipes, expiry, manual overrides, other Focus modes, offline devices, failures, and app termination. Export reviewed shareable shortcuts only after validation; do not assume local receipts prove iPhone delivery.
3. **Work-session/effect integration tests:** injectable adapters and clock; test UI intent changes during in-flight effects, lock-event activity, repeated lifecycle notifications, startup, pause, and quit without triggering OS effects.

## v0.2 — Improve presence and phone-only feasibility

4. **Calibrated BLE signals:** hardware experiment with a dedicated beacon; document packet intervals, false departure rate, battery impact, and RSSI thresholds. Add a calibration UI and privacy-preserving diagnostic export only with opt-in.
5. **Companion feasibility:** prototype an authenticated connection with a deliberate Mac/iPhone central/peripheral arrangement. Test background, locked phone, force-quit, and reconnect. Explore Watch participation without treating Auto Unlock as an API. Stop or pivot if reliability fails.
6. **iPhone-only Focus:** evaluate supported personal automation triggers or an optional relay. Document exactly how it executes on iOS, latency, required hardware/subscriptions, privacy, and behavior with Share Across Devices off. A silent push, URL, or companion alone is not a solution. Preserve the local lock-only mode.

## v1.0 — Ship a dependable utility

7. **Release engineering and pilot:** Developer ID signing/notarization, permissions/onboarding, an explicit OS/device support matrix, long-running battery/reliability pilot, reproducible release artifacts, accessible UI, and opt-in automatic start after validation. Fully automatic return requires a validated desktop-session signal.

No phase introduces auto-unlock, authentication bypass, analytics by default, or a paid cloud dependency into the base app.
