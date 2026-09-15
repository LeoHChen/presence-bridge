#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
swift build -c release "$@"
BIN_DIR="$(swift build -c release --show-bin-path "$@")"
APP_PATH="${PRESENCE_APP_PATH:-$PROJECT_ROOT/dist/Presence Bridge.app}"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$BIN_DIR/PresenceBridge" "$APP_PATH/Contents/MacOS/PresenceBridge"
cp Resources/Info.plist "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -lint "$APP_PATH/Contents/Info.plist"
/usr/bin/codesign --force --sign "${PRESENCE_SIGN_IDENTITY:--}" --options runtime "$APP_PATH"
/usr/bin/codesign --verify --strict "$APP_PATH"
printf 'Built %s\n' "$APP_PATH"
