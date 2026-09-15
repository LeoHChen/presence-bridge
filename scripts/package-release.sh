#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Package from a committed source revision, without replacing a running development app.
if [[ -n "$(git status --porcelain)" ]]; then
    printf 'Commit or stash source changes before packaging a release.\n' >&2
    exit 1
fi
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
RELEASE_DIR="$PROJECT_ROOT/dist/releases"
mkdir -p "$RELEASE_DIR"
STAGING_DIR="$(mktemp -d "$PROJECT_ROOT/dist/.release-stage.XXXXXX")"
trap 'rm -rf "$STAGING_DIR"' EXIT
PACKAGE_NAME="PresenceBridge-$VERSION-macos-universal"
PACKAGE_DIR="$STAGING_DIR/$PACKAGE_NAME"
APP_PATH="$PACKAGE_DIR/Presence Bridge.app"
mkdir -p "$PACKAGE_DIR"

PRESENCE_APP_PATH="$APP_PATH" bash scripts/build-app.sh --arch arm64 --arch x86_64
EXECUTABLE="$APP_PATH/Contents/MacOS/PresenceBridge"
/usr/bin/lipo -verify_arch arm64 x86_64 "$EXECUTABLE"
/usr/bin/codesign --verify --deep --strict "$APP_PATH"
"$EXECUTABLE" --self-check
cp LICENSE "$PACKAGE_DIR/LICENSE.txt"
cp docs/install.md "$PACKAGE_DIR/INSTALL.md"
{
    printf 'Presence Bridge %s\nSource: https://github.com/LeoHChen/presence-bridge\n' "$VERSION"
    printf 'Commit: %s\n' "$(git rev-parse HEAD)"
    printf 'Architectures: %s\n' "$(/usr/bin/lipo -archs "$EXECUTABLE")"
    printf 'Minimum macOS: %s\n' "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' Resources/Info.plist)"
    printf 'Built on macOS: %s (%s)\n' "$(sw_vers -productVersion)" "$(sw_vers -buildVersion)"
    swift --version
    printf '\nSigning details (packaging does not perform notarization):\n'
    /usr/bin/codesign -dv "$APP_PATH" 2>&1 | /usr/bin/sed '/^Executable=/d'
} > "$PACKAGE_DIR/BUILD-INFO.txt"
# Include only the staged app and public installation/license/build information.
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --norsrc --noextattr --keepParent \
    "$PACKAGE_DIR" "$RELEASE_DIR/$PACKAGE_NAME.zip"
cp "$PACKAGE_DIR/BUILD-INFO.txt" "$RELEASE_DIR/$PACKAGE_NAME-build-info.txt"
cp "$PACKAGE_DIR/INSTALL.md" "$RELEASE_DIR/INSTALL.md"
(
    cd "$RELEASE_DIR"
    /usr/bin/shasum -a 256 "$PACKAGE_NAME.zip" "$PACKAGE_NAME-build-info.txt" INSTALL.md > SHA256SUMS.txt
    /usr/bin/shasum -a 256 -c SHA256SUMS.txt
)
printf 'Release files: %s\n' "$RELEASE_DIR"
