// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "FoundationModelsTools",
  platforms: [
    .macOS(.v26),
    .iOS(.v26),
  ],
  products: [
    .library(
      name: "FoundationModelsTools",
      targets: ["FoundationModelsTools"])
  ],
  targets: [
    .target(
      name: "FoundationModelsTools",
      path: "Sources"
    ),
    .testTarget(
      name: "FoundationModelsToolsTests",
      dependencies: ["FoundationModelsTools"]
    )
  ]
)
