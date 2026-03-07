// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FoundationLabCore",
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
