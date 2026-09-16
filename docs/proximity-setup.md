# iPhone / Apple Watch walk-away locking

The first implementation listened only for advertisements. The current implementation also attempts a public Core Bluetooth connection to the device you choose and reads its signal every two seconds. This is a practical path to test with a stock iPhone or Watch, without installing a companion first. It is independent of Apple's secure Auto Unlock system.

A local Apple Watch test maintained an active connection and showed a clear signal difference between desk and another room. The generic −78 dBm threshold was too weak for that setup; calibration is essential. Actual automatic locking remains a separate acceptance test.

Compatibility is not guaranteed. An advertised name is not proof of device identity. Use only a device you own and can physically move during the test.

## 1. Build and open the local app

```sh
bash scripts/test.sh
bash scripts/build-app.sh
open "dist/Presence Bridge.app"
```

The app opens a control panel and also appears in the menu bar. It starts with lock/Focus effects off. Choose one stable app location before granting Accessibility or enabling login launch.

## 2. Find your device

1. Keep the phone or watch next to the Mac. Unlock/wake it during initial discovery.
2. Enable **Use iPhone / Watch proximity** and approve the system Bluetooth prompt if asked.
3. Select your device from the picker. It shows only useful advertised names and remembers your choice on this Mac. A restored choice stays visible as waiting until rediscovered. Leave **Maintain an active Bluetooth connection** on.
4. Watch the connection status and sample counter. A healthy active path reports **Connected; signal … dBm** repeatedly. If a connection cannot be established, advertisements remain a fallback and the status says so.
5. Lock the phone or let the Watch screen turn off. Check that valid samples continue for several minutes while it remains near the Mac.

Only the selected device receives a connection attempt. The app does not enumerate protected characteristics, read private Bluetooth databases, or request the Mac's login password. If an unrecognized pairing dialog appears, cancel it and investigate rather than approving blindly.

## 3. Calibrate and run an effect-free walk test

1. Place/wear the device as you normally do at the desk.
2. After at least three valid samples, click **Calibrate at desk**.
3. Wait for three fresh near observations, then click **Test detection only**.
4. Stop touching the Mac and take the selected device away. Ask someone to observe the panel if needed. The panel should change through **leaving** to **away**, with **Walk-away detected. No lock was sent.**
5. Return and check that the signal returns to **near/present**. Repeat with the phone locked or Watch screen off.

The walk test runs the same presence engine with lock and Focus effects disabled. It does not simulate radio loss. It must pass with real movement before claiming that your device works.

### Timing and thresholds

- Connection signal is sampled at most every two seconds. Initial defaults use an 8 dB hysteresis band and three qualifying smoothed samples.
- Calibration sets the leave threshold about 15 dB below the desk signal, bounded to −100…−45 dBm.
- Raising the leave threshold (for example, −78 → −60 dBm) generally detects departure sooner, but can cause false locks. Signal strength is not meters.
- No valid signal for more than 8 seconds means far. Departure then requires 8 seconds of grace. With one-second app polling, complete signal loss typically produces away about 16–17 seconds after the last sample.
- Input within 5 seconds vetoes departure. Moving the mouse during a walk test deliberately cancels it.
- After the device has been confirmed near, prolonged loss of the Mac's Bluetooth radio is also departure evidence. Reconnection does not reset the expiry clock.
- A device left on the desk cannot bypass the separate idle timeout.

Calibration is session-only for now. Changing the device, threshold, sensor, or connection mode pauses effects and requires a new **Start work** action.

## 4. Enable real locking

After the walk test succeeds:

1. Enable **Lock automatically when away**.
2. Grant Accessibility to the exact Presence Bridge app you are running.
3. Save work and test **Lock now**. Confirm the actual password-protected lock screen appears.
4. Return, wait for a fresh near signal, and click **Start work** / **I’m back**.
5. Walk away with the selected device. Verify that the Mac really locks.

Check **Recent activity** for the device departure, grace period, lock request, and observed lock. After unlocking normally, it also records the unlock and automatic resume. The history is session-only and can be cleared from the panel.

The app requests Control-Command-Q; successful event posting is not confirmed locking. It never unlocks the Mac. Apple Watch Auto Unlock may handle authentication independently when you return.

### Permission appears enabled, but locking fails

On the tested macOS 27 system, the permission page is named **System Settings → Privacy & Security → Device Control and Data Access**. Earlier macOS versions call it **Accessibility**.

If **Lock now** reports that permission is missing, first quit and reopen the app. If it still fails, quit the app, remove the Presence Bridge entry from that permission page, add the exact `.app` bundle you are currently running, and enable its switch. Authenticate in macOS if requested, then reopen Presence Bridge. Do not grant a different copy with the same display name. Merely adding the current bundle over an existing entry did not fix the tested local mismatch; removing the entry first did.

Local builds are ad-hoc signed, and permissions may need reapproval after a rebuild. Keep one stable app location, finish building before granting access, and repeat **Lock now** after replacing the executable. Relaunching clears session calibration and effect toggles; reconnect, recalibrate at your desk, and enable the desired effects again.

## Local diagnostic command

An explicit diagnostic prints nearby names and RSSI to the invoking terminal and never runs lock or Focus effects:

```sh
"dist/Presence Bridge.app/Contents/MacOS/PresenceBridge" --diagnose-bluetooth 40
```

To connect only to an exact, owner-confirmed advertised name:

```sh
"dist/Presence Bridge.app/Contents/MacOS/PresenceBridge" \
  --diagnose-bluetooth 120 --device-name 'Your device name'
```

The maximum diagnostic duration is five minutes. Duplicate matching names are not automatically selected. Do not commit or publish raw diagnostic output: names can identify people or nearby devices. The app does not upload it.

## If the device does not work

- Wake/unlock it for discovery and verify the name. Phone names may not always appear.
- Compare active and passive modes; look for stable RSSI before trying locks.
- If samples stop while the device is still beside the Mac, increase confidence through testing rather than calling every missing advertisement a successful departure.
- If stock-device connections remain unusable, the next experiment is an authenticated iPhone companion with a maintained GATT connection. A separate watchOS app has much tighter background budgets and is not automatically a better solution.

References: [Core Bluetooth connect](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/connect(_:options:)), [readRSSI](https://developer.apple.com/documentation/corebluetooth/cbperipheral/readrssi()), [BLEUnlock's public project description](https://github.com/ts1/BLEUnlock), [watchOS background Bluetooth limits](https://developer.apple.com/documentation/watchkit/using-background-tasks).
