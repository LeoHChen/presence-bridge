# Launch at login

## Preferred: native login item

1. Build the app and place a stable copy at `/Applications/Presence Bridge.app`.
2. Open it and choose **Launch at login → Enable**.
3. If requested, approve it in System Settings → General → Login Items.
4. Use **Disable** to unregister it.

The app uses `SMAppService.mainApp`. Local ad-hoc builds can behave differently from signed releases. Permissions may need reapproval after rebuilding. Launching at login starts observation only; choose effects and **Start work** each time.

## Development alternative: user LaunchAgent

Use this only instead of the native login item, never alongside it. Inspect [`Resources/io.github.leohchen.presence-bridge.plist.example`](../Resources/io.github.leohchen.presence-bridge.plist.example) and verify the executable's absolute path before installation. It launches in the logged-in graphical user session, not as root. There is no KeepAlive loop.

Install deliberately from the repository:

```sh
mkdir -p "$HOME/Library/LaunchAgents"
cp Resources/io.github.leohchen.presence-bridge.plist.example \
  "$HOME/Library/LaunchAgents/io.github.leohchen.presence-bridge.plist"
plutil -lint "$HOME/Library/LaunchAgents/io.github.leohchen.presence-bridge.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/io.github.leohchen.presence-bridge.plist"
```

Uninstall:

```sh
launchctl bootout "gui/$(id -u)/io.github.leohchen.presence-bridge"
rm "$HOME/Library/LaunchAgents/io.github.leohchen.presence-bridge.plist"
```

No installer script in this repository changes your login items automatically. Do not run the app or its launch agent with `sudo`.
