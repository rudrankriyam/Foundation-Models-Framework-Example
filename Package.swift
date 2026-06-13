// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationModelsFrameworkLab",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
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
            name: "FoundationModelsKit",
            path: "Packages/FoundationModelsKit/Sources/FoundationModelsKit"
        ),
        .target(
            name: "FoundationModelsTools",
            dependencies: ["FoundationModelsKit"],
            path: "Packages/FoundationModelsKit/Sources/FoundationModelsTools"
        ),
        .testTarget(
            name: "FoundationModelsKitTests",
            dependencies: ["FoundationModelsKit"],
            path: "Packages/FoundationModelsKit/Tests/FoundationModelsKitTests"
        ),
        .testTarget(
            name: "FoundationModelsToolsTests",
            dependencies: ["FoundationModelsTools"],
            path: "Packages/FoundationModelsKit/Tests/FoundationModelsToolsTests"
        )
    ]
)
