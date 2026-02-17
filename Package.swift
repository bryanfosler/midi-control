// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MIDIControl",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MIDIControl",
            path: "Sources/MIDIControl"
        )
    ]
)
