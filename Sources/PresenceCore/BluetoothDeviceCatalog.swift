import Foundation

/// A privacy-conscious representation used to decide which Bluetooth names belong in the picker.
public struct BluetoothDeviceCandidate: Equatable, Sendable {
    public let identifier: UUID
    public let name: String
    public let rssi: Int
    public let lastSeen: TimeInterval
    public let isSelected: Bool

    public init(identifier: UUID, name: String, rssi: Int, lastSeen: TimeInterval,
                isSelected: Bool = false) {
        self.identifier = identifier
        self.name = name
        self.rssi = rssi
        self.lastSeen = lastSeen
        self.isSelected = isSelected
    }
}

public enum BluetoothDeviceCatalog {
    private static let placeholders: Set<String> = [
        "unknown", "unknown device", "unnamed", "unnamed device", "no name",
        "not available", "n/a", "null", "(null)", "device"
    ]

    /// Returns a short human-readable name, or nil when Core Bluetooth only supplied a placeholder.
    public static func meaningfulName(_ rawName: String?) -> String? {
        guard let rawName else { return nil }
        let withoutControls = rawName.unicodeScalars
            .filter { !CharacterSet.controlCharacters.contains($0) }
            .map(String.init).joined()
        let clean = withoutControls.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        let lower = clean.lowercased()
        guard !placeholders.contains(lower), UUID(uuidString: clean) == nil else { return nil }

        let identifierCharacters = CharacterSet(charactersIn: "0123456789abcdefABCDEF:-")
        if clean.count >= 12,
           clean.unicodeScalars.allSatisfy({ identifierCharacters.contains($0) }) {
            return nil
        }
        return String(clean.prefix(60))
    }

    /// Keeps selection stable while making the current choice easy to find.
    public static func sorted(_ candidates: [BluetoothDeviceCandidate]) -> [BluetoothDeviceCandidate] {
        candidates.sorted { lhs, rhs in
            if lhs.isSelected != rhs.isSelected { return lhs.isSelected }
            if lhs.lastSeen != rhs.lastSeen { return lhs.lastSeen > rhs.lastSeen }
            let lhsSignal = lhs.rssi == 127 ? Int.min : lhs.rssi
            let rhsSignal = rhs.rssi == 127 ? Int.min : rhs.rssi
            if lhsSignal != rhsSignal { return lhsSignal > rhsSignal }
            let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.identifier.uuidString < rhs.identifier.uuidString
        }
    }
}

public struct StoredDeviceSelection: Equatable, Sendable {
    public let identifier: UUID
    public let name: String

    public init(identifier: UUID, name: String) {
        self.identifier = identifier
        self.name = name
    }

    /// The fallback supports preferences written by releases that stored only the UUID.
    public static func restore(identifier: String?, name: String?) -> StoredDeviceSelection? {
        guard let identifier, let uuid = UUID(uuidString: identifier) else { return nil }
        return StoredDeviceSelection(
            identifier: uuid,
            name: BluetoothDeviceCatalog.meaningfulName(name) ?? "Previously selected device"
        )
    }
}
