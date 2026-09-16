import Foundation

public enum ActivityKind: String, Equatable, Sendable {
    case session
    case bluetooth
    case lock
    case returnState
    case error
}

public struct ActivityEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let kind: ActivityKind
    public let message: String

    public init(id: UUID = UUID(), date: Date = Date(), kind: ActivityKind, message: String) {
        self.id = id
        self.date = date
        self.kind = kind
        self.message = message
    }
}

/// Bounded, in-memory history. Exact consecutive duplicates are coalesced.
public struct ActivityHistory: Sendable {
    public let capacity: Int
    public private(set) var entries: [ActivityEntry] = []

    public init(capacity: Int = 75) {
        self.capacity = max(1, capacity)
    }

    public mutating func record(_ kind: ActivityKind, _ message: String, at date: Date = Date()) {
        let clean = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        if let first = entries.first, first.kind == kind, first.message == clean { return }
        entries.insert(ActivityEntry(date: date, kind: kind, message: clean), at: 0)
        if entries.count > capacity { entries.removeLast(entries.count - capacity) }
    }

    public mutating func clear() {
        entries.removeAll(keepingCapacity: true)
    }
}
