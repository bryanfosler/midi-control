// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MIDIControl",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "/Users/bryan/utils/swift")
    ],
    targets: [
        .executableTarget(
            name: "MIDIControl",
            dependencies: [.product(name: "ProgressTracker", package: "swift")],
            path: "Sources/MIDIControl"
        )
    ]
)
