# Automatic return (unreleased)

Version 0.1.0 required **I'm back** because its screen-wake/session notifications did not establish that the Mac had finished unlocking. The intended everyday flow is to unlock normally and keep working.

## New behavior

**Resume after unlocking** defaults on. During an already-active work session:

1. The app observes that the Mac is locked and holds lock/Focus effects.
2. The user unlocks through macOS normally, including Apple's independent Watch Auto Unlock when configured.
3. The app waits for an available desktop and a fresh **near** reading from the selected Bluetooth device. Idle-only mode does not require Bluetooth.
4. After readiness stays stable for two seconds, the current work session resumes. The next departure can lock again.

**Pause**, quitting, a new launch, and a lock performed while the app was observing do not auto-start a work session. Screen wake, lock-screen typing, a lock request alone, or a nearby Watch alone cannot resume it. Manual Focus overrides remain in effect; automatic return does not create a new user-authorized Focus session.

If the Watch reconnects slowly, the app waits for it instead of resuming into an immediate weak-signal lock. **I'm back** remains the fallback if the OS lock cycle was missed or the compatibility signal is unavailable. Sleep without an observed lock/unlock cycle also uses that fallback.

## macOS compatibility boundary

The documented `NSWorkspace.sessionDidBecomeActiveNotification` reports a user session switching in; it is not a general authentication-completed notification. `CGSessionCopyCurrentDictionary()` is public, but its `CGSSessionScreenIsLocked` dictionary entry is **undocumented**. The project now uses that entry as a compatibility signal, not as an authentication API or security guarantee.

The lock flag normally disappears on unlock. Initial absence is treated as unknown: the tracker must first observe the flag in the locked state. The return policy separately requires a locked observation in each waiting cycle, available console/login state, device readiness, and a settling delay. A missing session or malformed flag cannot trigger return. The adapter reads no user names or other session details and writes no session logs.

If Apple changes this entry's meaning, behavior may break; the manual fallback remains necessary. The feature performs no authentication, stores no password, and never unlocks the Mac. An OS lock-state hint must not be reused as authorization for sensitive operations.

References: [Apple's session-switch notification](https://developer.apple.com/documentation/appkit/nsworkspace/sessiondidbecomeactivenotification), [public session query](https://developer.apple.com/documentation/coregraphics/cgsessioncopycurrentdictionary()), [documented dictionary keys](https://developer.apple.com/documentation/coregraphics/window-server-session-properties), and the independently implemented [BLEUnlock project](https://github.com/ts1/BLEUnlock) as an example of existing lock-state-field usage.

## Validation

Policy tests cover a full cycle, subsequent departures, delayed Bluetooth reconnection, pause/restart, disabled auto-resume, lock-screen input, unavailable sessions, transient signal loss, unknown state, and invalid clocks. A local unlocked-session probe confirmed that the lock field is absent on the tested Mac; that alone does not validate the complete lock/unlock transition.

Before releasing: with an active calibrated Watch session, lock and unlock normally; confirm **Work resumed automatically after unlock**, then walk away again and verify a second real lock. Also check pause-through-unlock and remaining on the lock screen while the Watch is near. The currently published v0.1.0 remains unchanged.
