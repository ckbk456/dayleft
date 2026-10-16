// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Dayleft",
  platforms: [.macOS(.v14)],
  products: [.library(name: "DayleftCore", targets: ["DayleftCore"])],
  targets: [
    .target(name: "DayleftCore"),
    .testTarget(name: "DayleftCoreTests", dependencies: ["DayleftCore"]),
  ],
  swiftLanguageModes: [.v6]
)
