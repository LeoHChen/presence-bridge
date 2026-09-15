// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PresenceBridge",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PresenceCore", targets: ["PresenceCore"]),
        .executable(name: "PresenceBridge", targets: ["PresenceBridge"])
    ],
    targets: [
        .target(name: "PresenceCore"),
        .executableTarget(name: "PresenceBridge", dependencies: ["PresenceCore"]),
        .testTarget(name: "PresenceCoreTests", dependencies: ["PresenceCore"])
    ]
)
