// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Dayleft",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "DayleftCore", targets: ["DayleftCore"]),
    .library(name: "DayleftPresentation", targets: ["DayleftPresentation"]),
  ],
  targets: [
    .target(name: "DayleftCore"),
    .target(name: "DayleftPresentation", dependencies: ["DayleftCore"]),
    .testTarget(name: "DayleftCoreTests", dependencies: ["DayleftCore"]),
    .testTarget(
      name: "DayleftPresentationTests", dependencies: ["DayleftCore", "DayleftPresentation"]),
  ],
  swiftLanguageModes: [.v6]
)
