// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
	name: "combine-cocoa-navigation",
	platforms: [
		.iOS(.v13),
		.macOS(.v11),
		.tvOS(.v13),
		.watchOS(.v6),
		.macCatalyst(.v13)
	],
	products: [
		.library(
			name: "CombineNavigation",
			targets: ["CombineNavigation"]
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/apple/swift-docc-plugin.git",
			.upToNextMajor(from: "1.3.0")
		),
		.package(
			url: "https://github.com/capturecontext/swift-capture.git",
			.upToNextMajor(from: "3.0.1")
		),
		.package(
			url: "https://github.com/capturecontext/cocoa-aliases.git",
			.upToNextMajor(from: "2.0.5")
		),
		.package(
			url: "https://github.com/capturecontext/swift-foundation-extensions.git",
			.upToNextMinor(from: "0.4.0")
		),
		.package(
			url: "https://github.com/pointfreeco/swift-case-paths",
			.upToNextMajor(from: "1.0.0")
		),
		.package(
			url: "https://github.com/pointfreeco/swift-macro-testing.git",
			.upToNextMinor(from: "0.2.0")
		),
		.package(
			url: "https://github.com/stackotter/swift-macro-toolkit.git",
			.upToNextMinor(from: "0.3.0")
		),
	],
	targets: [
		.target(
			name: "CombineNavigation",
			dependencies: [
				.target(name: "CombineNavigationMacros"),
				.product(
					name: "Capture",
					package: "swift-capture"
				),
				.product(
					name: "CasePaths",
					package: "swift-case-paths"
				),
				.product(
					name: "CocoaAliases",
					package: "cocoa-aliases"
				),
				.product(
					name: "FoundationExtensions",
					package: "swift-foundation-extensions"
				),
			]
		),
		.macro(
			name: "CombineNavigationMacros",
			dependencies: [
				.product(
					name: "MacroToolkit",
					package: "swift-macro-toolkit"
				)
			]
		),
		.testTarget(
			name: "CombineNavigationTests",
			dependencies: [
				.target(name: "CombineNavigation")
			]
		),
		.testTarget(
			name: "CombineNavigationMacrosTests",
			dependencies: [
				.target(name: "CombineNavigationMacros"),
				.product(name: "MacroTesting", package: "swift-macro-testing"),
			]
		),
	]
)
