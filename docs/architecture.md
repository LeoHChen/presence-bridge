# Architecture

## Scope

The first release proves a local Mac presence-to-action loop. It exposes uncertainty instead of equating radio reception with a person's identity. macOS owns authentication; Shortcuts and Apple's Focus sync own Focus changes. No backend, account system, analytics, iPhone app, or watchOS app is required by this MVP.

## Components

| Component | Responsibility |
|---|---|
| `PresenceEngine` | Decide unknown / present / leaving / away / suspended from monotonic samples |
| `ProximityFilter` / `DevicePresence` | Exponential RSSI smoothing, hysteresis, three observations, freshness, radio-loss handling, and near-before-arm eligibility |
| `FocusPolicy` | Serialize effects, track possible ownership, renew, back off, respect skipped recipes |
| `AppModel` | Poll every second; gate effects behind a user-started work session; handle sleep and return |
| `BluetoothMonitor` | Opt-in discovery, selected-device connection, two-second RSSI polling, timeout/reconnect, and passive fallback on the main queue |
| `ScreenLocker` | Request Apple's Control-Command-Q shortcut using public Core Graphics APIs |
| `ShortcutRunner` | Run fixed shortcut names without a shell; validate output receipts; enforce a local process timeout |
| SwiftUI menu bar | Status, effect toggles, device selection, pause, manual return, login item controls |

## Presence policy

Use `ProcessInfo.systemUptime` for elapsed intervals; wall-clock changes cannot shorten a departure countdown.

1. An unavailable desktop session produces `suspended`; invalid idle data produces `unknown`. Neither enables Focus or triggers an automatic lock.
2. Input within 5 seconds vetoes Bluetooth departure (30 seconds in idle-only mode).
3. A selected device that has become far or stale may begin departure after that veto expires.
4. Otherwise, the idle threshold (default 300 seconds) begins departure. This still applies when a beacon is near, since the phone may be left on the desk.
5. `leaving` must persist for 8 seconds in Bluetooth mode or 15 seconds in idle-only mode before `away`. New activity or recovered presence cancels the countdown. Focus can remain active during this grace period.
6. An `away` transition while armed requests one lock if enabled and stops requesting Focus. The work session is latched until **I’m back**. Injected lock-key events cannot restart work.

Bluetooth is a hint that can accelerate departure, never an authentication factor. Arming Bluetooth locking requires fresh near observations. Once established, missing signal expires after 8 seconds; loss of the Mac radio also becomes far after 8 seconds. The departure grace then applies. Before a device is established, unavailable radio/unknown device do not invent a departure. Explicitly changing sensors, devices, thresholds, or connection mode pauses effects and requires re-arming. Interference can still cause an early departure. Calibration and a hardware validation pass are required.

## Work state and return

The app deliberately distinguishes its presence estimate from permission to run effects. It launches with effects disarmed and scanning off. **Start work** arms the current session; effect toggles are separate. Screen sleep, system sleep, session switching, and detected departure require **I’m back** before effects resume.

Public workspace notifications cover screen and session lifecycle events, but are not a universal authenticated screen-lock/unlock API. `CGSessionCopyCurrentDictionary` is read only through its documented console/login keys. This MVP does not read undocumented lock-state keys, subscribe to private lock notifications, or inspect Apple security processes. A manual lock while the display remains awake may not be detected immediately; the idle timeout/Focus lease bounds the fallback. The next milestone must improve and validate this before promising fully automatic return.

## Focus lifecycle

The user creates three reserved recipes: On (only with no current Focus), Renew (only while At Mac is active), and Off (only while At Mac is active). On/Renew set an explicit expiry 15 minutes ahead. Renew runs every 5 minutes while the work gate permits Focus. A recipe returns a plain-text receipt. Receipts confirm only local shortcut execution, not delivery to the iPhone.

- One action runs at a time. If the user leaves while On is in flight, Off is selected after its completion.
- A `skipped` receipt suppresses acquisition until a new explicitly started session. Renew cannot reactivate a Focus the user turned off.
- Ambiguous On/Renew failures suppress new acquisition but preserve possible cleanup responsibility.
- Off failures retry no faster than every 30 seconds. Other actions are not blindly retried.
- CLI execution has a 20-second timeout, followed by termination and a 2-second grace before killing that local CLI process. Apple's Shortcuts service may still finish work after the CLI exits; the app cannot revoke an already submitted action.
- Pause and Quit attempt Off. Quit waits up to 25 seconds. Crashes, forced termination, sleep, or an unavailable iPhone may prevent cleanup; the user-configured lease is the fallback.

Ownership is advisory. There is no atomic Focus compare-and-set or public token tied to this app. Reserve **At Mac** for the bridge. If a user manually selects the same Focus, the app cannot distinguish it. Other named Focus modes are guarded by the recipes, subject to a race between reading and setting Focus. No previous Focus is restored because On never intentionally replaces one.

## Persistence and transport

Only idle timeout and selected peripheral UUID persist in app preferences. Advertised names/RSSI and state are memory-only. There is no event history or app telemetry. Shortcuts output uses a private temporary directory that is removed after execution; a crash can leave a small receipt file until system cleanup. The app has no network client or listener; shared Focus travels through Apple's services outside the app.

## Delivery

Swift Package Manager keeps the initial project small and dependency-free. A script assembles an `LSUIElement` application bundle with Bluetooth usage text and ad-hoc signing. `SMAppService.mainApp` supplies opt-in login launch; an example LaunchAgent is provided for development. Signing/notarization and long-running hardware validation remain release work.

## Active Bluetooth adapter

Retain the selected CBPeripheral, call connect, and read RSSI at most every two seconds while connected. Connection attempts time out after 15 seconds and back off for five seconds. An RSSI response missing for six seconds triggers reconnection. Disconnection does not reset signal freshness, so reconnect attempts cannot indefinitely prevent departure. Advertisements supply fallback measurements when connected RSSI is unavailable. The adapter reads no services/characteristics from the selected device. Public standard-service retrieval only helps discover devices already connected by the system. No connections are made to other discovered devices.

Calibration chooses a leave threshold 15 dB below the current desk signal, bounded to −100…−45 dBm, with an 8 dB hysteresis band. It resets the samples and requires fresh calibration evidence before arming. Calibration is session-only. Device names are not authenticated. The bounded discovery list prioritizes named devices over rotating anonymous advertisements.

The explicit diagnostic command prints local names/RSSI to its invoking terminal. It does not store a log itself or run effects. Its output should not be committed or shared without redaction.
