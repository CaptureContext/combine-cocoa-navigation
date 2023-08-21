# combine-cocoa-navigation

[![SwiftPM 5.8](https://img.shields.io/badge/swiftpm-5.8-ED523F.svg?style=flat)](https://swift.org/download/) ! [![@maximkrouk](https://img.shields.io/badge/contact-@capturecontext-1DA1F2.svg?style=flat&logo=twitter)](https://twitter.com/capture_context) 

## Usage

Basically all you need is to call `configureRoutes` method of the viewController, it accepts routing publisher and routeConfigurations, your code may look somewhat like this:

```swift
final class MyViewController: UIViewController {
  // ...
  
  func bindViewModel() {
    configureRoutes(
      for viewModel.publisher(for: \.state.route),
      routes: [
        // Provide mapping from route to controller
        .associate(makeDetailsController, with: .details)
      ],
      onDismiss: { 
        // Update state on dismiss
        viewModel.send(.dismiss)
      }
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
  .upToNextMinor(from: "0.2.0")
)
```

Do not forget about target dependencies:

```swift
.product(
  name: "CombineNavigation", 
  package: "combine-cocoa-navigation"
)

## License

This package is released under the MIT license. See [LICENSE](./LICENSE) for details.
