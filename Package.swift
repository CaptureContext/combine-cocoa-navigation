// swift-tools-version:5.8

import PackageDescription

let package = Package(
  name: "combine-cocoa-navigation",
  platforms: [
    .iOS(.v13),
    .macOS(.v11),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "CombineNavigation",
      targets: ["CombineNavigation"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/capturecontext/cocoa-aliases.git",
      .upToNextMajor(from: "2.0.5")
    ),
    .package(
      url: "https://github.com/capturecontext/swift-foundation-extensions.git",
      .upToNextMinor(from: "0.2.0")
    ),
    .package(
      url: "https://github.com/capturecontext/combine-extensions.git",
      .upToNextMinor(from: "0.1.0")
    ),
  ],
  targets: [
    .target(
      name: "CombineNavigation",
      dependencies: [
        .product(
          name: "CocoaAliases",
          package: "cocoa-aliases"
        ),
        .product(
          name: "FoundationExtensions",
          package: "swift-foundation-extensions"
        ),
        .product(
          name: "CombineExtensions",
          package: "combine-extensions"
        ),
      ]
    )
  ]
)
