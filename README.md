# Presence Bridge

[![Swift checks](https://github.com/LeoHChen/presence-bridge/actions/workflows/ci.yml/badge.svg)](https://github.com/LeoHChen/presence-bridge/actions/workflows/ci.yml)

A local-first macOS menu bar app that estimates when you leave your desk, requests a Mac lock, and runs Apple Shortcuts to manage an **At Mac** Focus.

**Status: developer MVP, not a security product.** Native Swift/SwiftUI, macOS 13+, no dependencies, MIT licensed. The app starts in observation mode. Automatic actions and Bluetooth scanning require explicit opt-in on each launch.

## What works, and what does not

| Capability | This MVP |
|---|---|
| Detect Mac activity | Reads seconds since input; no keystroke content |
| Estimate departure | Idle timeout plus a 15-second grace period |
| Optional Bluetooth signal | Core Bluetooth scan of a selected advertising BLE device; smoothed RSSI and stale-signal handling |
| Apple Watch proximity | **Not available:** Apple's Auto Unlock proximity/authentication signal is not exposed as a public app API |
| Ordinary iPhone as a beacon | **Not reliable:** a nearby or paired iPhone is not guaranteed to advertise a stable, continuously discoverable BLE identity |
| Automatically lock the Mac | Opt-in Control-Command-Q request through public event APIs; requires Accessibility and device testing |
| Automatically change iPhone Focus | User-created Mac shortcuts change a **shared** Focus, which Apple syncs to the iPhone |
| Silence only the iPhone, keep all Mac notifications | **Not implemented:** shared Focus also affects the Mac; disabling Focus sharing prevents this bridge reaching the iPhone |
| Return after locking/sleep | Unlock normally, then click **I’m back**; unattended return detection is deferred |
| Apple Watch Auto Unlock | Continues to be an independent Apple feature; this app never unlocks the Mac |

The original goal is fewer duplicate phone notifications while working on a Mac. The shared-Focus path is a practical starting point, **not a complete solution to phone-only notification suppression**. Focus is a coarse notification policy; this project cannot detect that the Mac already delivered an individual notification.

## Quick start

Requires a Mac with Swift 6.0+ (Xcode 16+ or compatible Command Line Tools) and the built-in Shortcuts app. An iPhone on the same Apple Account is needed only for shared Focus. Platform minimums are compile targets, not a completed hardware support matrix; see [validation](docs/validation.md).

```sh
git clone https://github.com/LeoHChen/presence-bridge.git
cd presence-bridge
swift test --disable-xctest
bash scripts/build-app.sh
open "dist/Presence Bridge.app"
```

1. Open the person icon in the menu bar. Observe the state and idle counter first.
2. For Focus, create **At Mac** and the three shortcuts in the [Shortcuts setup guide](docs/shortcuts.md). Enable **Share Across Devices** on the Mac and iPhone. Test the notification effect on both devices.
3. For locking, enable **Lock automatically when away**, grant Accessibility to **Presence Bridge**, and test **Lock now** after saving your work. Visually verify that the Mac requires authentication.
4. Choose the desired effects, then **Start work**. Default departure is 5 minutes without input plus 15 seconds of grace. A far/missing selected BLE beacon can shorten this to 30 seconds of inactivity plus grace.
5. After departure, locking, screen sleep, or session switching, unlock if necessary and click **I’m back**. **Pause** stops automatic effects and attempts to release the Focus lease.

Use a stable copy in `/Applications/Presence Bridge.app` before granting permissions or enabling **Launch at login**. Local builds are ad-hoc signed, not notarized. Do not disable Gatekeeper or SIP. Each launch starts in observation mode, including login launches.

## Bluetooth is optional

Turn on **Scan Bluetooth (experimental)**, explicitly select your advertising BLE device, and observe it both at the desk and away. A tested dedicated beacon is a better experiment than relying on undocumented Watch/iPhone advertisements. Device names are not identity proof. The app neither pairs with devices nor connects to services.

RSSI thresholds are initial defaults, not meters: near at −65 dBm or stronger, far at −78 dBm or weaker, three qualifying smoothed observations, and 12 seconds before a previously seen device becomes stale. With Bluetooth off, denied, or never observed, the normal idle timeout applies. A beacon left on the desk cannot suppress the idle timeout.

## Architecture

```mermaid
flowchart LR
    A[Mac idle time] --> D[Presence engine]
    B[Optional BLE scan] --> C[RSSI smoothing and freshness]
    C --> D
    S[Screen and session events] --> D
    D --> E[Work-session gate and departure grace]
    E --> L[Opt-in Mac lock request]
    E --> F[Serialized Focus policy]
    F --> X[Mac Shortcuts CLI]
    X --> M[Shared At Mac Focus]
    M --> I[iPhone via Apple Focus sync]
    U[User: Start work / I’m back / Pause] --> E
```

- [`Sources/PresenceCore`](Sources/PresenceCore): deterministic presence, proximity, and Focus policies, with tests.
- [`Sources/PresenceBridge`](Sources/PresenceBridge): SwiftUI menu bar, public Mac sensors, lock requests, Shortcuts execution, and login item support.
- [`docs/architecture.md`](docs/architecture.md): state transitions, failure handling, boundaries.
- [`docs/platform-limitations.md`](docs/platform-limitations.md): Apple documentation and what it means for this design.
- [`docs/shortcuts.md`](docs/shortcuts.md): guarded On/Renew/Off recipes with a 15-minute expiry.
- [`docs/roadmap.md`](docs/roadmap.md): staged milestones and acceptance criteria.
- [`SECURITY.md`](SECURITY.md): permissions, privacy, and failure modes.

## Development

```sh
swift build
swift test --disable-xctest
swift run PresenceBridge --self-check
bash scripts/build-app.sh
```

Open `Package.swift` in Xcode for source navigation and debugging. Run the packaged `.app` for a stable bundle identity and privacy prompts. CI tests the policies, builds the bundle, and runs an effect-free executable check. No lock, Bluetooth, or Focus automation is exercised in CI.

For a user-session LaunchAgent alternative, see [launch at login](docs/launch-at-login.md). Use only one login mechanism. No root daemon or privileged helper is needed.

Contributions are welcome; start with [CONTRIBUTING.md](CONTRIBUTING.md) and the [issues](https://github.com/LeoHChen/presence-bridge/issues). See [LICENSE](LICENSE).
