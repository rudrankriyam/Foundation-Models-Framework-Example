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
    dependencies: [
        .package(url: "https://github.com/rudrankriyam/FoundationModelsTools.git", branch: "main")
    ],
    targets: [
        .target(
            name: "FoundationLabCore",
            dependencies: [
                .product(name: "FoundationModelsTools", package: "FoundationModelsTools")
            ]
        ),
        .testTarget(
            name: "FoundationLabCoreTests",
            dependencies: ["FoundationLabCore"]
        )
    ]
)
