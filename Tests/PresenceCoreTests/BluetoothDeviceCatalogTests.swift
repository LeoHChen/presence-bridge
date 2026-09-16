import Foundation
import Testing
@testable import PresenceCore

struct BluetoothDeviceCatalogTests {
    @Test func keepsMeaningfulNamesAndCleansControlCharacters() {
        #expect(BluetoothDeviceCatalog.meaningfulName("Hao’s Apple Watch") == "Hao’s Apple Watch")
        #expect(BluetoothDeviceCatalog.meaningfulName("  Leo’s iPhone\n") == "Leo’s iPhone")
        #expect(BluetoothDeviceCatalog.meaningfulName("AirPods\u{0000} Pro") == "AirPods Pro")
    }

    @Test func filtersUnknownAndIdentifierLikeNames() {
        for name in [nil, "", "Unknown", "unnamed device", "N/A",
                     "91E6670C-1B68-4B73-9EC9-40B3F4A1EE31", "AA:BB:CC:DD:EE:FF"] {
            #expect(BluetoothDeviceCatalog.meaningfulName(name) == nil)
        }
    }

    @Test func selectedDeviceSortsFirstThenRecentAndStrong() {
        let selected = BluetoothDeviceCandidate(identifier: UUID(), name: "Watch", rssi: -80,
                                                lastSeen: 1, isSelected: true)
        let recent = BluetoothDeviceCandidate(identifier: UUID(), name: "Phone", rssi: -70, lastSeen: 20)
        let older = BluetoothDeviceCandidate(identifier: UUID(), name: "Headphones", rssi: -20, lastSeen: 10)
        #expect(BluetoothDeviceCatalog.sorted([older, recent, selected]).map(\.name)
            == ["Watch", "Phone", "Headphones"])
    }

    @Test func restoresLegacySelectionWithoutStoredName() {
        let id = UUID()
        #expect(StoredDeviceSelection.restore(identifier: id.uuidString, name: nil)
            == StoredDeviceSelection(identifier: id, name: "Previously selected device"))
        #expect(StoredDeviceSelection.restore(identifier: "bad", name: "Watch") == nil)
    }
}
