#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

public protocol _PresentationDestinationProtocol: AnyObject {
	@_spi(Internals)
	func _initControllerForPresentationIfNeeded() -> CocoaViewController

	@_spi(Internals)
	func _invalidate()
}

/// Wrapper for creating and accessing managed navigation destination controller
///
/// > ⚠️ Sublasses or typealiases must contain "PresentationDestination" in their name
/// > to be processed by `@RoutingController` macro
@propertyWrapper
open class PresentationDestination<Controller: CocoaViewController>:
	Weakifiable,
	_PresentationDestinationProtocol
{
	@_spi(Internals)
	open var _controller: Controller?

	internal(set) public var container: CocoaViewController?

	@usableFromInline
	internal var containerProvider: ((Controller) -> CocoaViewController)?

	open var wrappedValue: Controller? { _controller }

	@inlinable
	open var projectedValue: PresentationDestination<Controller> { self }

	@usableFromInline
	internal var _initControllerOverride: (() -> Controller)?

	@usableFromInline
	internal var _configuration: ((Controller) -> Void)?

	@inlinable
	public func setContainerProvider(
		_ containerProvider: PresentationDestinationContainerProvider<Controller>?
	) {
		self.containerProvider = containerProvider?._create
	}

	/// Sets instance-specific override for creating a new controller
	///
	/// This override has the highest priority when creating a new controller
	///
	/// To disable isntance-specific override pass `nil` to this method
	@inlinable
	public func overrideInitController(
		with closure: (() -> Controller)?
	) {
		_initControllerOverride = closure
	}

	/// Sets instance-specific configuration for controllers
	@inlinable
	public func setConfiguration(
		_ closure: ((Controller) -> Void)?
	) {
		_configuration = closure
		closure.map { configure in
			wrappedValue.map(configure)
		}
	}

	@_spi(Internals)
	@inlinable
	open class func initController() -> Controller {
		return __initializeDestinationController()
	}

	@_spi(Internals)
	@inlinable
	open func configureController(_ controller: Controller) {}

	@_disfavoredOverload
	public init() {}

	/// Creates a new instance of PresentationDestination
	///
	/// `initControllerOverride`*
	///
	///
	/// Default implementation is suitable for most controllers, however if you have a controller which
	/// doesn't have a custom init you'll have to use this method or if you have a base controller that
	/// requires custom init it'll be beneficial for you to create a custom subclass of `PresentationDestination`
	/// and override it's `initController` class method, you can find an example in tests.
	///
	/// - Parameters:
	///   - container:
	///   ContainerProvider that will wrap controller for presentation
	///   - initControllerOverride:
	///   This override has the highest priority when creating a new controller, default one is just `Controller()`
	///   **which can lead to crashes if controller doesn't have an empty init**.
	///   *Consider using `DestinationInitializableControllerProtocol` if possible instead of this parameter*
	public init(
		container: PresentationDestinationContainerProvider<Controller>? = nil,
		_ initControllerOverride: (() -> Controller)? = nil
	) {
		self.containerProvider = container?._create
		self._initControllerOverride = initControllerOverride
	}

	@_spi(Internals)
	@inlinable
	public func _initControllerForPresentationIfNeeded() -> CocoaViewController {
		return callAsFunction()
	}

	@_spi(Internals)
	open func _invalidate() {
		self._controller = nil
		self.container = nil
	}

	/// Returns `container`  if needed,  intializes and configures a new instance otherwise
	@discardableResult
	public func callAsFunction() -> CocoaViewController {
		let controller = wrappedValue ?? {
			let controller = _initControllerOverride?() ?? Self.initController()
			configureController(controller)
			_configuration?(controller)
			self._controller = controller
			self.container = containerProvider?(controller)
			return controller
		}()

		return container ?? controller
	}
}

public struct PresentationDestinationContainerProvider<
	Controller: CocoaViewController
> {
	@usableFromInline
	internal var _create: (Controller) -> CocoaViewController

	public init(_ create: @escaping (Controller) -> CocoaViewController) {
		self._create = create
	}

	@inlinable
	public func callAsFunction(_ controller: Controller) -> CocoaViewController {
		return _create(controller)
	}
}

extension PresentationDestinationContainerProvider {
	@inlinable
	public static var navigation: Self {
		.init(UINavigationController.init(rootViewController:))
	}
}
#endif
