// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FoundationLabCLI",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "fm",
            targets: ["FMCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
        .package(path: "../FoundationLabCore")
    ],
    targets: [
        .executableTarget(
            name: "FMCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FoundationLabCore", package: "FoundationLabCore")
            ],
            path: "Sources/FMCLI"
        )
    ]
)
