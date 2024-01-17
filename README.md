# combine-cocoa-navigation

[![SwiftPM 5.9](https://img.shields.io/badge/swiftpm-5.9-ED523F.svg?style=flat)](https://github.com/CaptureContext/swift-declarative-configuration/actions/workflows/Test.yml) ![Platforms](https://img.shields.io/badge/platforms-iOS_13_|_macOS_11_|_tvOS_13_|_watchOS_6_|_Catalyst_13-ED523F.svg?style=flat) [![@capture_context](https://img.shields.io/badge/contact-@capture__context-1DA1F2.svg?style=flat&logo=twitter)](https://twitter.com/capture_context) 

>Package compiles for all platforms, but functionality is available if UIKit can be imported and the platform is not watchOS.

> The branch is a `pre-release` version.

## Usage

This library was primarely created for [TCA](https://github.com/pointfreeco/swift-composable-architecture) navigation with Cocoa. However it's geneic enough to use with pure combine. But to dive more into general understanding of stack-based and tree based navigation take a look at TCA docs.

- See [`ComposableExtensions`](https://github.com/capturecontext/composable-architecture-extensions) if you use TCA, it provides better APIs for TCA.
- See [`Example`](./Example)_`(wip)`_ for more usage examples (_it uses [`ComposableExtensions`](https://github.com/capturecontext/composable-architecture-extensions), but th API is similar_).
- See [`Docs`](https://swiftpackageindex.com/capturecontext/combine-cocoa-navigation/1.0.0/documentation/combinenavigation) for documentation reference.

### Setup

It's **extremely important** to call `bootstrap()` function in the beginning of your app's lifecycle to perform required swizzling for enabling

- `UINavigationController.popPublisher`
- `UIViewController.dismissPublisher`
- `UIViewController.selfDismissPublisher`

Maybe someday a bug in the compiler will be fixed and we may introduce automatic bootstrap.

```swift
import UIKit
import CombineNavigation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [
      UIApplication.LaunchOptionsKey: Any
    ]?
  ) -> Bool {
    CombineNavigation.bootstrap()
    return true
  }
}
```

### Tree-based navigation

Basically all you need is to call `navigationDestination` method of the viewController, it accepts routing publisher and mapping of the route to the destination controller. Your code may look somewhat like this:

```swift
enum MyFeatureRoute {
  case details
}

@RoutingController
final class MyViewController: UIViewController {
  @TreeDestination
  var detailsController: DetailsViewController?

  func bindViewModel() {
    navigationDestination(
      viewModel.publisher(for: \.state.route),
      switch: { destinations, route in
        switch route {
        case .details:
          destinations.$detailsController
        }
      },
      onPop: capture { _self in 
        _self.viewModel.send(.dismiss)
      }
    ).store(in: &cancellables)
  }
}
```

or

```swift
enum MyFeatureState {
  // ...
  var details: DetailsState?
}

final class MyViewController: UIViewController {
  @TreeDestination
  var detailsController: DetailsViewController?
  
  func bindViewModel() {
    navigationDestination(
      "my_feature_details"
      isPresented: viewModel.publisher(for: \.state.detais.isNotNil),
      destination: $detailsController,
      onPop: capture { $0.viewModel.send(.dismiss) }
    ).store(in: &cancellables)
  }
}
```

### Stack-based navigation

Basically all you need is to call `navigationStack` method of the viewController, it accepts routing publisher and mapping of the route to the destination controller. Your code may look somewhat like this:

```swift
enum MyFeatureState {
  enum DestinationState {
    case featureA(FeatureAState)
    case featureB(FeatureBState)
  }
  // ...
  var path: [DestinationState]
}

final class MyViewController: UIViewController {
  @StackDestination
  var featureAControllers: [Int: FeatureAController]
  
  @StackDestination
  var featureBControllers: [Int: FeatureBController]
  
  func bindViewModel() {
    navigationStack(
      viewModel.publisher(for: \.state.path),
      switch: { destinations, route in
        switch route {
        case .featureA:
          destinations.$featureAControllers
        case .featureB:
          destinations.$featureBControllers
        }
      },
      onPop: capture { _self, indices in
        // can be handled like `state.path.remove(atOffsets: IndexSet(indices))`
        // should remove all requested indices before publishing an update
        _self.viewModel.send(.dismiss(indices))
      }
    ).store(in: &cancellables)
  }
}
```

### Presentation

Basically all you need is to call `presentationDestination` method of the viewController, it accepts routing publisher and mapping of the route to the destination controller. Your code may look somewhat like this:

```swift
enum MyFeatureDestination {
  case details
}

@RoutingController
final class MyViewController: UIViewController {
  @PresentationDestination
  var detailsController: DetailsViewController?

  func bindViewModel() {
    presentationDestination(
      viewModel.publisher(for: \.state.destination),
      switch: { destinations, route in
        switch route {
        case .details:
          destinations.$detailsController
        }
      },
      onDismiss: capture { _self in 
        _self.viewModel.send(.dismiss)
      }
    ).store(in: &cancellables)
  }
}
```

or

```swift
enum MyFeatureState {
  // ...
  var details: DetailsState?
}

final class MyViewController: UIViewController {
  @PresentationDestination
  var detailsController: DetailsViewController?
  
  func bindViewModel() {
    presentationDestination(
      "my_feature_details"
      isPresented: viewModel.publisher(for: \.state.detais.isNotNil),
      destination: $detailsController,
      onDismiss: capture { $0.viewModel.send(.dismiss) }
    ).store(in: &cancellables)
  }
}
```

## Installation

### Basic

You can add CombineNavigation to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Swift Packages › Add Package Dependency…**
2. Enter [`"https://github.com/capturecontext/combine-cocoa-navigation.git"`](https://github.com/capturecontext/combine-cocoa-navigation.git) into the package repository URL text field
3. Choose products you need to link them to your project.

### Recommended

If you use SwiftPM for your project, you can add CombineNavigation to your package file.

```swift
.package(
  url: "https://github.com/capturecontext/combine-cocoa-navigation.git", 
  branch: "navigation-stacks"
)
```

Do not forget about target dependencies:

```swift
.product(
  name: "CombineNavigation", 
  package: "combine-cocoa-navigation"
)
```

## License

This package is released under the MIT license. See [LICENSE](./LICENSE) for details.

