// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VoiceLog",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VoiceLog", targets: ["VoiceLog"])
    ],
    targets: [
        .executableTarget(
            name: "VoiceLog",
            path: "Sources/VoiceLog"
        ),
        .testTarget(
            name: "VoiceLogTests",
            dependencies: ["VoiceLog"],
            path: "Tests/VoiceLogTests"
        )
    ]
)
