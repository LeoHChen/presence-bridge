# ADR-0001: Local native MVP with shared Focus shortcuts

**Status:** Accepted for the developer MVP; sensor approach extended by [ADR-0002](0002-active-device-proximity.md)

**Date:** 2026-09-15

**Deciders:** Initial project implementation; future changes reviewed by maintainers

## Context

The desired behavior is to silence an iPhone while its owner works on a Mac and lock the Mac when they leave. Apple's Watch Auto Unlock proximity is not a public application signal. A Mac cannot generally execute arbitrary iPhone shortcuts remotely, and shared Focus can silence the Mac as well. The first version must be useful and honest about those constraints.

## Decision

Build a dependency-free Swift/SwiftUI menu bar app for macOS 13+. Use idle time plus optional selected BLE advertisements to estimate departure, a public keyboard-event lock request, and local Shortcuts recipes to control a finite shared-Focus lease. Start disarmed. Require a user interaction to resume after departure/sleep until authenticated return detection is validated. Do not build an iPhone/watchOS companion merely to imply unsupported background behavior.

## Options considered

| Option | Benefits | Costs / limits |
|---|---|---|
| Native menu bar + shared Focus | Small, local, inspectable, no backend, working Mac control path | Shared Focus affects both devices; manual return in MVP |
| iPhone/watchOS companion first | Could support explicit pairing and richer presence signals | Background radio/execution limits; no arbitrary Focus setter; needs hardware proof |
| Cloud/webhook relay | Can deliver messages to a phone-side tool | Does not itself grant iOS execution; privacy, service costs, and possibly spare hardware |
| Private Apple integrations | Might expose convenient system state | Unsupported, fragile, inappropriate basis for a public security-adjacent tool |

## Consequences

The project can ship a reviewable native foundation immediately. Watch-specific ranging, automatic authenticated return, phone-only notification suppression, and release-quality lock assurance remain separate work. The pure policy layer can accept better sensors later without changing effect ownership or UI intent.

## Action items

- [x] Implement the policy layer, native menu, and opt-in adapters.
- [x] Document Focus recipes, privacy, and known limitations.
- [ ] Validate real Mac/iPhone behavior and improve lock/return assurance.
- [ ] Prove any companion or iPhone-only relay before committing to its implementation.
