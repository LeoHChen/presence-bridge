# Release procedure

## Prepare and validate

1. Update `Resources/Info.plist` version/build number, `CHANGELOG.md`, release notes, and versioned links in `README.md` and `docs/install.md`. Describe physical-test evidence separately from policy tests and compiler targets.
2. Review source changes, run `bash scripts/test.sh`, and commit the complete release source. Keep local device names, UUIDs, credentials, and diagnostic logs out of Git.
3. Run `bash scripts/package-release.sh` from a clean checkout. It builds arm64 and x86_64, verifies both architectures and the signature, runs the host's executable self-check, and packages only the app plus public license/install/build information. It leaves `dist/Presence Bridge.app` untouched.
4. Extract the ZIP into a separate directory, verify the extracted app signature, and run its `--self-check`. Confirm version, minimum OS, architectures, expected archive contents, build revision, and `SHA256SUMS.txt`. Never run sensors, Focus, or lock actions in CI.
5. Require passing PR checks before merging. After merge, package again from the exact clean main commit that will receive the tag, or download the `universal-preview-<commit>` artifact from the successful main-branch CI run. Review the source revision recorded in the archive. If any check fails, fix before publishing.

## Publish

Create an annotated version tag on the verified commit, push it, then create a GitHub release using `gh release create --verify-tag --prerelease --notes-file ...` and explicitly list the four files in `dist/releases/` (ZIP, build info, installation guide, checksums). Use a preview designation while device reliability, Intel/older-OS behavior, and end-to-end Focus remain incompletely tested.

Download the public release assets into a new directory after publishing. Verify the checksums against the verified build, archive contents, app signature, and executable self-check. Confirm the GitHub release tag resolves to the packaged source commit.

## Signing

The default package is ad-hoc signed. The published v0.1.0 preview explicitly documents this limitation and Apple's per-app approval flow. A local v0.2.0 candidate has been built with the project's Developer ID identity, but that alone does not make it notarized or ready to publish as an Apple-verified release.

`PRESENCE_SIGN_IDENTITY` can select an existing developer certificate for the build script; never commit certificates or passwords. A later notarized release also needs secure notarization credentials, submission, ticket stapling, and Gatekeeper validation before replacing this preview workflow. No certificate or credential is created by these scripts.

## Rollback

If a release contains an unexpected lock loop, corrupt download, or serious permission issue, remove the affected asset from public download, mark the release as withdrawn, and update its notes with the issue and last known-working version. Do not move an already-published tag. Publish corrected source and artifacts under a new version. Users can pause, quit, and remove the app; replacing its signature may require permission reapproval.

This first release has no older binary to roll back to. Withdrawal and disabling the app are the available recovery path.
