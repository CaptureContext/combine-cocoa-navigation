// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

#warning("TODO: Add rich example")
// The example is WIP, it's a simple twitter-like app
// but already has examples for Tree-based and recursive Tree-based
// navigation. Stack-based navigation is planned
//
// Do not forget to add it to repo before publishing a release ^^

#warning("TODO: Add docc and publish it on SPI")

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
			url: "https://github.com/capturecontext/swift-capture.git",
			.upToNextMajor(from: "3.0.1")
		),
		.package(
			url: "https://github.com/capturecontext/cocoa-aliases.git",
			.upToNextMajor(from: "2.0.5")
		),
		.package(
			url: "https://github.com/capturecontext/combine-extensions.git",
			.upToNextMinor(from: "0.1.0")
		),
		.package(
			url: "https://github.com/capturecontext/swift-foundation-extensions.git",
			.upToNextMinor(from: "0.3.4")
		),
		.package(
			url: "https://github.com/stackotter/swift-macro-toolkit.git",
			.upToNextMinor(from: "0.3.0")
		),
		.package(
			url: "https://github.com/pointfreeco/swift-macro-testing.git",
			.upToNextMinor(from: "0.2.0")
		)
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
					name: "CocoaAliases",
					package: "cocoa-aliases"
				),
				.product(
					name: "CombineExtensions",
					package: "combine-extensions"
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
