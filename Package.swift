// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationModelsFrameworkCLI",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "afm",
            targets: ["AFMCLI"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AFMCLI"
        ),
        .testTarget(
            name: "AFMCLITests",
            dependencies: ["AFMCLI"]
        )
    ]
)
