// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationLabCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "FoundationLabCore",
            targets: ["FoundationLabCore"]
        )
    ],
    targets: [
        .target(
            name: "FoundationLabCore"
        ),
        .testTarget(
            name: "FoundationLabCoreTests",
            dependencies: ["FoundationLabCore"]
        )
    ]
)
