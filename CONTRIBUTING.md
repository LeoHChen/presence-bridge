# Contributing

Start with an issue describing the user-visible problem, target devices/OS versions, and acceptance criteria. For platform behavior, prefer links to Apple's current public documentation and label observations separately from guarantees.

## Local checks

```sh
swift test --disable-xctest
bash scripts/build-app.sh
"dist/Presence Bridge.app/Contents/MacOS/PresenceBridge" --self-check
git diff --check
```

Tests use Swift Testing and require Swift 6.0+. If Command Line Tools cannot locate the test runtime, use a full Xcode installation or the repository’s macOS CI. A missing framework is not a passed suite.

Add deterministic tests for behavior changes to the policies. Never make CI lock a workstation or change Focus. For system integration changes, use the manual [validation checklist](docs/validation.md) and state exactly which devices were tested.

Keep new sensors opt-in. Do not add private Apple APIs, reverse-engineer Auto Unlock, capture input content, upload radio identifiers, or turn a convenience presence hint into an authentication factor. Propose changes to privacy and transport in an ADR first.

Pull requests should describe the changed behavior, relevant test results, and any remaining Apple-platform limitations. Avoid committing local device preferences, app bundles, signing keys, provisioning profiles, or credentials.
