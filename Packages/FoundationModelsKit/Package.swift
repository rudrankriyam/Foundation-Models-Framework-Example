// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationModelsKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "FoundationModelsKit",
            targets: ["FoundationModelsKit"]
        ),
        .library(
            name: "FoundationModelsTools",
            targets: ["FoundationModelsTools"]
        )
    ],
    targets: [
        .target(
            name: "FoundationModelsKit"
        ),
        .target(
            name: "FoundationModelsTools",
            dependencies: ["FoundationModelsKit"]
        ),
        .testTarget(
            name: "FoundationModelsKitTests",
            dependencies: ["FoundationModelsKit"]
        ),
        .testTarget(
            name: "FoundationModelsToolsTests",
            dependencies: ["FoundationModelsTools"]
        )
    ]
)
