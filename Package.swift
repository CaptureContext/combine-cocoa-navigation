// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "cocoa-combine-navigation",
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
      name: "cocoa-aliases",
      url: "https://github.com/capturecontext/cocoa-aliases.git",
      .upToNextMajor(from: "2.0.4")
    ),
    .package(
      name: "swift-foundation-extensions",
      url: "https://github.com/capturecontext/swift-foundation-extensions.git",
      .branch("main")
    ),
    .package(
      name: "combine-extensions",
      url: "https://github.com/capturecontext/combine-extensions.git",
      .upToNextMinor(from: "0.0.3")
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
