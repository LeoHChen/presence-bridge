# Set up the Focus bridge

## Choose the tradeoff first

This setup changes **shared Focus on the Mac and iPhone**. It cannot preserve fully independent Mac notification behavior while automatically toggling an iPhone-only Focus. If that is your requirement, use lock-only mode and follow the iPhone-only feasibility milestone.

This repository provides recipes, not fabricated `.shortcut` imports or preauthorized Focus settings. Build them in Apple's Shortcuts app. Action labels and variable pickers can vary by OS/language; validate them on your Mac before arming automation.

## 1. Create the Focus

1. On the iPhone, open Settings → Focus → + → Custom. Name it **At Mac**.
2. Choose the people and apps you want to silence; keep desired urgent contacts allowed.
3. Enable **Share Across Devices** in Focus settings on the iPhone and Mac, signed into the same Apple Account.
4. Check that At Mac appears on the Mac and that manually toggling it reaches the phone.
5. Observe notification behavior on both devices. The Mac may silence notifications too.

Reserve this named Focus for Presence Bridge. Avoid separate schedules or Smart Activation for it during testing. Keep **Share Focus Status** off if you do not want apps to tell contacts that you have silenced notifications; that is separate from device sharing.

## 2. Create three Mac shortcuts

Copy these names exactly, including the **em dash (—)**. Each recipe must end in **Stop and Output** with the indicated plain text, using a Text action if needed. Avoid alerts, menus, Ask for Input, and other interactive actions in the recipes. Never set Focus indefinitely.

### `Presence Bridge — Focus On`

```text
Get Current Focus
If Current Focus has any value:
    Stop and Output: skipped
Otherwise:
    Current Date
    Adjust Date: add 15 minutes
    Set Focus: turn At Mac On until [Adjusted Date / Time]
    Stop and Output: enabled
```

The app must not replace Sleep, Driving, Do Not Disturb, or a user-selected Focus. If At Mac is already on before starting, this recipe also skips; it does not claim ownership of an existing session.

### `Presence Bridge — Focus Renew`

```text
Get Current Focus
Get the Name of Current Focus (via its Name property / Get Name)
If Name is exactly At Mac:
    Current Date
    Adjust Date: add 15 minutes
    Set Focus: turn At Mac On until [Adjusted Date / Time]
    Stop and Output: renewed
Otherwise:
    Stop and Output: skipped
```

This recipe must **not** call On. When you manually turn Focus off or select a different Focus, Renew skips and the app suppresses further acquisition for the current work session. It does not turn your Focus back on. The check runs at renewal, so manual changes are not observed instantly.

### `Presence Bridge — Focus Off`

```text
Get Current Focus
Get the Name of Current Focus (via its Name property / Get Name)
If Name is exactly At Mac:
    Set Focus: turn At Mac Off
    Stop and Output: disabled
Otherwise:
    Stop and Output: skipped
```

Never substitute an unconditional “turn off current Focus” action. Use At Mac explicitly. If no Focus is active, the empty name should reach the Otherwise branch; verify this in your version of Shortcuts.

## 3. Test manually before enabling the bridge

These commands **change Focus**. Run them intentionally after building the recipes and reviewing their actions:

```sh
shortcuts run 'Presence Bridge — Focus On'
shortcuts run 'Presence Bridge — Focus Renew'
shortcuts run 'Presence Bridge — Focus Off'
```

Check the receipt text, the Mac Control Center, and the iPhone Control Center. Complete any permission prompts while present. Then enable **Run shared Focus shortcuts** in Presence Bridge and click **Start work**.

Acceptance checks:

- With no current Focus, On activates At Mac on both devices and returns `enabled`.
- At Mac expires about 15 minutes after the last On/Renew if the app cannot clean up.
- With another Focus active, all three recipes return `skipped` and preserve it.
- After manually turning At Mac off, Renew returns `skipped` and does not reactivate it.
- Pause/away invokes Off for a Focus the app may have enabled.
- Each recipe runs without interaction through the Mac command line.

## Failure behavior

The app serializes calls and renews every five minutes. A command failure or timeout produces a visible status. It cannot verify iPhone delivery, and killing the CLI does not necessarily cancel work submitted to the Shortcuts service. The finite lease limits lingering Focus after failure; synchronization timing remains Apple's behavior.

Use **Pause** and turn At Mac off manually if needed. After a restart, the app has no persisted ownership token; an existing At Mac lease is left to expire instead of being claimed. A manual use of the exact same Focus cannot be distinguished from a bridge-owned lease. Prefer a dedicated name and no other automations changing it.

See [platform limitations](platform-limitations.md) and [Apple's Shortcuts command-line guide](https://support.apple.com/guide/shortcuts-mac/apd455c82f02/mac).
