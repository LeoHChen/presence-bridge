import Foundation
import Testing
@testable import PresenceCore

struct ActivityHistoryTests {
    @Test func newestEntryComesFirstAndHistoryIsBounded() {
        var history = ActivityHistory(capacity: 2)
        history.record(.session, "Started", at: Date(timeIntervalSince1970: 1))
        history.record(.bluetooth, "Watch moved away", at: Date(timeIntervalSince1970: 2))
        history.record(.lock, "Mac lock observed", at: Date(timeIntervalSince1970: 3))
        #expect(history.entries.map(\.message) == ["Mac lock observed", "Watch moved away"])
    }

    @Test func exactConsecutiveDuplicatesAreCoalesced() {
        var history = ActivityHistory()
        history.record(.lock, "Lock requested")
        history.record(.lock, "Lock requested")
        history.record(.returnState, "Mac unlocked")
        history.record(.lock, "Lock requested")
        #expect(history.entries.count == 3)
    }

    @Test func clearRemovesAllEntries() {
        var history = ActivityHistory()
        history.record(.session, "Started")
        history.clear()
        #expect(history.entries.isEmpty)
    }
}
