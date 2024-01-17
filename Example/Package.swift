// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "CombineNavigationExample",
	platforms: [
		.iOS(.v17)
	],
	dependencies: [
		.package(
			url: "https://github.com/capturecontext/composable-architecture-extensions.git",
			branch: "observation-beta"
		),
		.package(
			url: "https://github.com/capturecontext/combine-extensions.git",
			.upToNextMinor(from: "0.1.0")
		),
		.package(
			url: "https://github.com/pointfreeco/swift-dependencies.git",
			.upToNextMajor(from: "1.0.0")
		),
		.package(
			url: "https://github.com/capturecontext/swift-foundation-extensions.git",
			.upToNextMinor(from: "0.4.0")
		),
		.package(
			url: "https://github.com/pointfreeco/swift-identified-collections.git",
			.upToNextMajor(from: "1.0.0")
		),
	],
	producibleTargets: [
		// MARK: - Utils
		// Basic extensions for every module
		// Ideally should be extracted to a separate `Extensions` package
		// See https://github.com/capturecontext/basic-ios-template
		// - Should not import compex dependencies
		// - Must not import targets from other sections

		.target(
			name: "LocalExtensions",
			product: .library(.static),
			dependencies: [
				.product(
					name: "CombineExtensions",
					package: "combine-extensions"
				),
				.product(
					name: "FoundationExtensions",
					package: "swift-foundation-extensions"
				),
				.product(
					name: "IdentifiedCollections",
					package: "swift-identified-collections"
				)
			],
			path: ._extensions("LocalExtensions")
		),

		// MARK: - Dependencies
		// Separate target for each dependency
		// Ideally should be extracted to a separate `Dependencies` package
		// See https://github.com/capturecontext/basic-ios-template
		// - Can import targets from `Utils` section
		// - Must not import targets from `Modules` section

		.target(
			name: "_ComposableArchitecture",
			product: .library(.static),
			dependencies: [
				.localExtensions,
				.product(
					name: "ComposableExtensions",
					package: "composable-architecture-extensions"
				)
			],
			path: ._dependencies("_ComposableArchitecture")
		),

		.target(
			name: "_Dependencies",
			product: .library(.static),
			dependencies: [
				.localExtensions,
				.product(
					name: "Dependencies",
					package: "swift-dependencies"
				)
			],
			path: ._dependencies("_Dependencies")
		),

		// MARK: - Modules
		// Application modules
		// - Can import any targets from sections above
		// - Should not import external dependencies directly
		// - Feature modules have suffix `Feature`
		// - Service and Model modules have no specific suffix

		.target(
			name: "APIClient",
			product: .library(.static),
			dependencies: [
				.target("AppModels"),
				.target("DatabaseSchema"),
				.dependency("_Dependencies"),
				.localExtensions
			]
		),

		.target(
			name: "AppFeature",
			product: .library(.static),
			dependencies: [
				.target("APIClient"),
				.target("AppUI"),
				.target("AuthFeature"),
				.target("MainFeature"),
				.target("OnboardingFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "AppModels",
			product: .library(.static),
			dependencies: [
				.dependency("_Dependencies"),
				.localExtensions
			]
		),

		.target(
			name: "AppUI",
			product: .library(.static),
			dependencies: [
				.localExtensions,
			]
		),

		.target(
			name: "AuthFeature",
			product: .library(.static),
			dependencies: [
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "CurrentUserProfileFeature",
			product: .library(.static),
			dependencies: [
				.target("AppModels"),
				.target("TweetsListFeature"),
				.target("UserSettingsFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "DatabaseSchema",
			product: .library(.static),
			dependencies: [
				.dependency("_Dependencies"),
				.localExtensions
			]
		),

		.target(
			name: "ExternalUserProfileFeature",
			product: .library(.static),
			dependencies: [
				.target("AppModels"),
				.target("TweetsListFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "FeedTabFeature",
			product: .library(.static),
			dependencies: [
				.target("AppUI"),
				.target("UserProfileFeature"),
				.target("TweetsFeedFeature"),
				.target("TweetPostFeature"),
				.target("ProfileAndFeedPivot"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "MainFeature",
			product: .library(.static),
			dependencies: [
				.target("FeedTabFeature"),
				.target("ProfileTabFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "OnboardingFeature",
			product: .library(.static),
			dependencies: [
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "ProfileAndFeedPivot",
			product: .library(.static),
			dependencies: [
				.target("TweetsFeedFeature"),
				.target("UserProfileFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "ProfileFeedFeature",
			product: .library(.static),
			dependencies: [
				.target("TweetFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "ProfileTabFeature",
			product: .library(.static),
			dependencies: [
				.target("AppModels"),
				.target("TweetsFeedFeature"),
				.target("UserProfileFeature"),
				.target("ProfileAndFeedPivot"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "TweetDetailFeature",
			product: .library(.static),
			dependencies: [
				.target("APIClient"),
				.target("TweetFeature"),
				.target("TweetsListFeature"),
				.target("TweetReplyFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "TweetFeature",
			product: .library(.static),
			dependencies: [
				.target("AppUI"),
				.target("AppModels"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "TweetPostFeature",
			product: .library(.static),
			dependencies: [
				.target("APIClient"),
				.target("AppUI"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "TweetReplyFeature",
			product: .library(.static),
			dependencies: [
				.target("TweetFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "TweetsFeedFeature",
			product: .library(.static),
			dependencies: [
				.target("TweetsListFeature"),
				.target("TweetDetailFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "TweetsListFeature",
			product: .library(.static),
			dependencies: [
				.target("TweetFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "UserProfileFeature",
			product: .library(.static),
			dependencies: [
				.target("CurrentUserProfileFeature"),
				.target("ExternalUserProfileFeature"),
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),

		.target(
			name: "UserSettingsFeature",
			product: .library(.static),
			dependencies: [
				.dependency("_ComposableArchitecture"),
				.localExtensions,
			]
		),
	]
)

// MARK: - Helpers

extension Target.Dependency {
	static var localExtensions: Target.Dependency {
		//	.product(name: "LocalExtensions", package: "Extensions")
		return .target("LocalExtensions")
	}

	static func dependency(_ name: String) -> Target.Dependency {
		// .product(name: name, package: "Dependencies")
		return .target(name)
	}

	static func target(_ name: String) -> Target.Dependency {
		.target(name: name)
	}
}

extension CustomTargetPathBuilder {
	static func _dependencies(_ module: String) -> Self {
		.init(module).nested(in: "_Dependencies").nested(in: "Sources")
	}

	static func _extensions(_ module: String) -> Self {
		.init(module).nested(in: "_Extensions").nested(in: "Sources")
	}
}

struct CustomTargetPathBuilder: ExpressibleByStringLiteral {
	private let build: (String) -> String

	func build(for targetName: String) -> String {
		build(targetName)
	}

	init(_ build: @escaping (String) -> String) {
		self.build = build
	}

	init(_ value: String) {
		self.init { _ in value }
	}

	init(stringLiteral value: String) {
		self.init(value)
	}

	static var targetName: Self {
		return .init { $0 }
	}

	func map(_ transform: @escaping (String) -> String) -> Self {
		return .init { transform(self.build(for: $0)) }
	}

	func nestedInSources() -> Self {
		return nested(in: "Sources")
	}

	func nested(in parent: String) -> Self {
		return map { "\(parent)/\($0)" }
	}

	func suffixed(by suffix: String) -> Self {
		return map { "\($0)\(suffix)" }
	}

	func prefixed(by prefix: String) -> Self {
		return map { "\(prefix)\($0)" }
	}
}

enum ProductType: Equatable {
	case executable
	case library(PackageDescription.Product.Library.LibraryType? = .static)
}

struct ProducibleTarget {
	init(
		target: Target,
		productType: ProductType? = .none
	) {
		self.target = target
		self.productType = productType
	}

	var target: Target
	var productType: ProductType?

	var product: PackageDescription.Product? {
		switch productType {
		case .executable:
			// return .executable(name: target.name, targets: [target.name])
			return nil
		case .library(let type):
			return .library(name: target.name, type: type, targets: [target.name])
		case .none:
			return nil
		}
	}

	static func target(
		name: String,
		product productType: ProductType? = nil,
		dependencies: [Target.Dependency] = [],
		path: CustomTargetPathBuilder? = nil,
		exclude: [String] = [],
		sources: [String]? = nil,
		resources: [Resource]? = nil,
		publicHeadersPath: String? = nil,
		packageAccess: Bool = true,
		cSettings: [CSetting]? = nil,
		cxxSettings: [CXXSetting]? = nil,
		swiftSettings: [SwiftSetting]? = nil,
		linkerSettings: [LinkerSetting]? = nil,
		plugins: [Target.PluginUsage]? = nil
	) -> ProducibleTarget {
		ProducibleTarget(
			target: productType == .executable
			? .executableTarget(
				name: name,
				dependencies: dependencies,
				path: path?.build(for: name),
				exclude: exclude,
				sources: sources,
				resources: resources,
				publicHeadersPath: publicHeadersPath,
				packageAccess: packageAccess,
				cSettings: cSettings,
				cxxSettings: cxxSettings,
				swiftSettings: swiftSettings,
				linkerSettings: linkerSettings,
				plugins: plugins
			)
			: .target(
				name: name,
				dependencies: dependencies,
				path: path?.build(for: name),
				exclude: exclude,
				sources: sources,
				resources: resources,
				publicHeadersPath: publicHeadersPath,
				packageAccess: packageAccess,
				cSettings: cSettings,
				cxxSettings: cxxSettings,
				swiftSettings: swiftSettings,
				linkerSettings: linkerSettings,
				plugins: plugins
			),
			productType: productType
		)
	}

	static func testTarget(
		name: String,
		dependencies: [Target.Dependency] = [],
		path: CustomTargetPathBuilder? = nil,
		exclude: [String] = [],
		sources: [String]? = nil,
		resources: [Resource]? = nil,
		packageAccess: Bool = true,
		cSettings: [CSetting]? = nil,
		cxxSettings: [CXXSetting]? = nil,
		swiftSettings: [SwiftSetting]? = nil,
		linkerSettings: [LinkerSetting]? = nil,
		plugins: [Target.PluginUsage]? = nil
	) -> ProducibleTarget {
		ProducibleTarget(
			target: .testTarget(
				name: name,
				dependencies: dependencies,
				path: path?.build(for: name),
				exclude: exclude,
				sources: sources,
				resources: resources,
				packageAccess: packageAccess,
				cSettings: cSettings,
				cxxSettings: cxxSettings,
				swiftSettings: swiftSettings,
				linkerSettings: linkerSettings,
				plugins: plugins
			),
			productType: .none
		)
	}
}

extension Package {
	convenience init(
		name: String,
		defaultLocalization: LanguageTag? = nil,
		platforms: [SupportedPlatform]? = nil,
		pkgConfig: String? = nil,
		providers: [SystemPackageProvider]? = nil,
		dependencies: [Dependency] = [],
		producibleTargets: [ProducibleTarget],
		swiftLanguageVersions: [SwiftVersion]? = nil,
		cLanguageStandard: CLanguageStandard? = nil,
		cxxLanguageStandard: CXXLanguageStandard? = nil
	) {
		self.init(
			name: name,
			defaultLocalization: defaultLocalization,
			platforms: platforms,
			pkgConfig: pkgConfig,
			providers: providers,
			products: producibleTargets.compactMap(\.product),
			dependencies: dependencies,
			targets: producibleTargets.map(\.target),
			swiftLanguageVersions: swiftLanguageVersions,
			cLanguageStandard: cLanguageStandard,
			cxxLanguageStandard: cxxLanguageStandard
		)
	}
}
