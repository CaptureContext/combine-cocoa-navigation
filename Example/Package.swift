// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "CombineNavigationExample",
	platforms: [
		.iOS(.v16)
	],
	products: [
		.library(
			name: "CombineNavigationExample",
			targets: ["CombineNavigationExample"]
		),
	],
	dependencies: [
		.package(path: ".."),
		.package(
			url: "https://github.com/pointfreeco/swift-composable-architecture.git",
			.upToNextMajor(from: "1.5.0")
		),
	],
	targets: [
		.target(
			name: "CombineNavigationExample",
			dependencies: [
				.product(
					name: "ComposableArchitecture",
					package: "swift-composable-architecture"
				),
				.product(
					name: "CombineNavigation",
					package: "combine-cocoa-navigation"
				)
			]
		)
	]
)
