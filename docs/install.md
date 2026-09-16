# Install Presence Bridge (preview)

Published downloads: https://github.com/LeoHChen/presence-bridge/releases

Version 0.2.0 is currently a local release candidate with automatic return after unlocking, a named-device picker with remembered selection, session activity history, and reliable menu-bar window restore. The published v0.1.0 requires **I'm back** instead. The app displays its version; the included build-info file identifies the exact source revision.

## Requirements and release status

- macOS 13 or later. The ZIP contains both Apple Silicon and Intel code.
- This is an experimental preview. The physical Watch walk-away test passed on one Apple Silicon Mac running macOS 27. Other Mac/device combinations need their own calibration and walk test; Intel hardware has not been field-tested.
- The published v0.1.0 download is ad-hoc signed. Local v0.2.0 release candidates are Developer ID signed when their build information names `Developer ID Application: Hao Chen (79DDZ6D8WT)`, but are not yet notarized. macOS may block an unnotarized first launch. Review the matching source, build information, and checksums before deciding to run it.
- There is no installer, privileged helper, backend, or automatic updater. All actions start disabled on each launch.

## Download and open

1. Download the **PresenceBridge-VERSION-macos-universal.zip** asset for the chosen release, or use the local test package provided to you. Optional verification: put **SHA256SUMS.txt**, **INSTALL.md**, and the matching build-info file into the same folder, then run `shasum -a 256 -c SHA256SUMS.txt` there. These checks detect mismatched downloads; they do not replace Apple signing or notarization.
2. Expand the ZIP and drag **Presence Bridge.app** to **Applications**. Open that copy and keep using the same location.
3. If macOS blocks an unidentified or unnotarized app, and you have chosen to trust this release, follow Apple's per-app **Open Anyway** process in **System Settings → Privacy & Security**: https://support.apple.com/en-us/102445. Managed Macs may disallow exceptions. Do not disable Gatekeeper or SIP, remove quarantine in bulk, or override a malware/damaged-app warning.

## Set up Watch or iPhone departure locking

1. Turn on **Use iPhone / Watch proximity** and allow Bluetooth access. Wake your Watch or iPhone if needed for discovery. Choose your own device from the named list; the app remembers and displays that selection on later launches. Leave **Maintain an active Bluetooth connection** enabled.
2. Wait for connected, fresh **near** readings while sitting normally at the desk. Click **Calibrate at desk**, then wait for at least three new samples.
3. Optionally click **Test detection only** (**Test walking away** in v0.1.0). Take the device into another room for 30–40 seconds without touching the Mac. This test pauses automatic actions and sends no lock command. Return and confirm that the app detected departure and now sees the device near again.
4. Enable **Lock automatically when away**. Grant the exact app Accessibility permission. On the tested macOS 27 system, this page is named **Privacy & Security → Device Control and Data Access**; earlier versions call it **Accessibility**.
5. Save work and click **Lock now**. Verify that the Mac locks and requires normal authentication to return.
6. Wait for a near reading, click **I'm back** or **Start work**, and repeat the walk with the device. **ACTIVE** means automatic actions are armed. In v0.2.0, leave **Resume after unlocking** enabled: an active session should resume after an observed lock/unlock cycle and two seconds of stable desktop/device readiness. Check **Recent activity** for the departure, lock, unlock, and **Work resumed automatically after unlock**, then walk away again to test the next lock. Version 0.1.0 always requires **I'm back**; v0.2.0 retains it as a fallback if the OS lock signal is unavailable. Bluetooth never unlocks the Mac.

**Pause** stops automatic actions. Closing or minimizing the panel leaves the app running; click its lock icon in the right side of the menu bar and choose **Open Presence Bridge** to bring it back. The recent activity list is stored only in memory and clears when the app quits. After quitting/relaunching, turn Bluetooth and the desired effects back on, recalibrate, and click **Start work** again. Calibration is session-only in this preview. You can use Apple's Auto Unlock independently.

If the permission switch is enabled but **Lock now** still fails, quit Presence Bridge, remove its old permission entry, add the current Applications copy, enable access, and reopen the app. Rebuilding or replacing an app with a different signature can require reapproval. Full setup: https://github.com/LeoHChen/presence-bridge/blob/main/docs/proximity-setup.md

## Optional shared Focus

Watch locking does not require Shortcuts. Leave **Run shared Focus shortcuts** off unless you have created and tested the three recipes at https://github.com/LeoHChen/presence-bridge/blob/main/docs/shortcuts.md.

The integration changes a shared Focus on both Mac and iPhone. It does not implement iPhone-only silencing or detect individual duplicate notifications. End-to-end Focus behavior has not yet been field-tested.

## Remove or roll back

Click **Pause**, disable **Launch at login** if enabled, and quit Presence Bridge before replacing or removing the app. If you used Focus, check that **At Mac** is off on both devices. Remove only this app's Bluetooth/control permission entries if desired. For a future update, quit first and keep a known-working release; changes to the app signature may require permission reapproval.

Report issues: https://github.com/LeoHChen/presence-bridge/issues
Do not include device identifiers, nearby people's device names, or raw Bluetooth logs.
