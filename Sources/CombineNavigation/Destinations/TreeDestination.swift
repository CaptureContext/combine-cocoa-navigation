#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

public protocol SingleDestinationProtocol {
	@_spi(Internals)
	func _initControllerIfNeeded() -> CocoaViewController

	@_spi(Internals)
	func _invalidateDestination()
}

/// Wrapper for creating and accessing managed navigation destination controller
///
/// > ⚠️ Sublasses or typealiases must contain "TreeDestination" in their name
/// > to be processed by `@RoutingController` macro
@propertyWrapper
open class TreeDestination<Controller: CocoaViewController>:
	Weakifiable,
	SingleDestinationProtocol
{
	@_spi(Internals)
	open var _controller: Controller?

	open var wrappedValue: Controller? { _controller }

	@inlinable
	open var projectedValue: TreeDestination<Controller> { self }
	
	@usableFromInline
	internal var _initControllerOverride: (() -> Controller)?

	@usableFromInline
	internal var _configuration: ((Controller) -> Void)?

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
		return Controller()
	}
	
	@_spi(Internals) 
	@inlinable
	open func configureController(_ controller: Controller) {}

	/// Creates a new instance
	public init() {}
	
	/// Creates a new instance with instance-specific override for creating a new controller
	///
	/// This override has the highest priority when creating a new controller, default one is just `Controller()`
	/// **which can lead to crashes if controller doesn't have an empty init**
	///
	/// Default implementation is suitable for most controllers, however if you have a controller which
	/// doesn't have a custom init you'll have to use this method or if you have a base controller that
	/// requires custom init it'll be beneficial for you to create a custom subclass of TreeDestination
	/// and override it's `initController` class method, you can find an example in tests.
	@inlinable
	public convenience init(_ initControllerOverride: @escaping () -> Controller) {
		self.init()
		self.overrideInitController(with: initControllerOverride)
	}

	@_spi(Internals)
	@inlinable
	public func _initControllerIfNeeded() -> CocoaViewController {
		self.callAsFunction()
	}

	@_spi(Internals)
	@inlinable
	open func _invalidateDestination() {
		self._controller = nil
	}

	/// Returns wrappedValue if present, intializes and configures a new instance otherwise
	public func callAsFunction() -> Controller {
		let controller = wrappedValue ?? {
			let controller = _initControllerOverride?() ?? Self.initController()
			configureController(controller)
			_configuration?(controller)
			self._controller = controller
			return controller
		}()
		return controller
	}
}
#endif
