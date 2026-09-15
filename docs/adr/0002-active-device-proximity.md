# ADR-0002: Try stock-device active Bluetooth before a companion

**Status:** Accepted for experimental implementation; physical validation pending

**Date:** 2026-09-15

## Context

Phone/Watch departure is a critical requirement. The initial passive scanner was insufficiently ambitious, and the phrase “Watch proximity unavailable” conflated Apple's private Auto Unlock signal with ordinary BLE reception. Public projects such as BLEUnlock demonstrate an active-connection approach worth testing. A local read-only scan also observed repeated Watch advertisements; it did not establish ownership or validate departure.

## Decision

Attempt a public Core Bluetooth connection only to the explicitly selected device, poll connected RSSI every two seconds, reconnect after timeout/disconnection, and use advertisements as fallback. Preserve freshness through connection failure. Add a near-before-arm gate, eight-second signal expiry, desk calibration, a faster departure policy, and an effect-free walk test.

No upstream implementation code is copied. We do not use private Bluetooth databases or scrape Apple's Watch/Continuity services. We also do not reproduce auto-unlock behavior or store a login password.

## Alternatives

- **Passive only:** simpler but can lose signals when stock devices stop advertising.
- **Companion first:** may provide explicit pairing and heartbeat behavior, but requires iOS signing/install and background-lifecycle validation. Keep it as the fallback if stock-device connections fail.
- **Watch app first:** watchOS background alert/scan budgets limit frequent app-driven heartbeats. A Watch app is not equivalent to access to the OS Auto Unlock feature.

## Consequences

The desired walk-away behavior now has a concrete implementation and test path without requiring a phone app. Compatibility and physical distance sensitivity remain unproven until an owner-confirmed device passes locked/idle and movement tests. Radio failure after an established session can intentionally cause a lock; users must understand that tradeoff. Shared Focus limitations and manual return remain unchanged.
