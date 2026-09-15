#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
PRESENCE_DEVELOPER_PATH="$(xcode-select -p)"
PRESENCE_TEST_PLUGIN="$PRESENCE_DEVELOPER_PATH/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
# Some Swift 6.4 CLT builds omit this installed macro library from incremental test invocations.
# Full Xcode and older layouts use the normal SwiftPM discovery path.
if [[ "$PRESENCE_DEVELOPER_PATH" == */CommandLineTools && -f "$PRESENCE_TEST_PLUGIN" ]]; then
    swift test --disable-xctest -Xswiftc -load-plugin-library -Xswiftc "$PRESENCE_TEST_PLUGIN" "$@"
else
    swift test --disable-xctest "$@"
fi
