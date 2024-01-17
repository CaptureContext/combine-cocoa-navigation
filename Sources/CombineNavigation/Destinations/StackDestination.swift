#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

public protocol _StackDestinationProtocol<DestinationID>: AnyObject {
	associatedtype DestinationID: Hashable

	@_spi(Internals)
	func _initControllerIfNeeded(for id: DestinationID) -> CocoaViewController

	@_spi(Internals)
	func _invalidate(_ id: DestinationID)
}

/// Wrapper for creating and accessing managed navigation stack controllers
///
/// > ⚠️ Sublasses or typealiases must contain "StackDestination" in their name
/// > to be processed by `@RoutingController` macro
@propertyWrapper
open class StackDestination<
	DestinationID: Hashable,
	Controller: CocoaViewController
>: Weakifiable, _StackDestinationProtocol {
	@_spi(Internals)
	open var _controllers: [DestinationID: Controller] = [:]

	open var wrappedValue: [DestinationID: Controller] {
		_controllers
	}

	@inlinable
	open var projectedValue: StackDestination<DestinationID, Controller> { self }

	@usableFromInline
	internal var _initControllerOverride: ((DestinationID) -> Controller)?

	@usableFromInline
	internal var _configuration: ((Controller, DestinationID) -> Void)?

	/// Sets instance-specific override for creating a new controller
	///
	/// This override has the highest priority when creating a new controller
	///
	/// To disable isntance-specific override pass `nil` to this method
	@inlinable
	public func overrideInitController(
		with closure: ((DestinationID) -> Controller)?
	) {
		_initControllerOverride = closure
	}

	/// Sets instance-specific configuration for controllers
	@inlinable
	public func setConfiguration(
		_ closure: ((Controller, DestinationID) -> Void)?
	) {
		_configuration = closure
		closure.map { configure in
			wrappedValue.forEach { id, controller in
				configure(controller, id)
			}
		}
	}

	@_spi(Internals)
	@inlinable
	open class func initController(
		for id: DestinationID
	) -> Controller {
		return __initializeDestinationController()
	}

	@_spi(Internals)
	@inlinable
	open func configureController(
		_ controller: Controller,
		for id: DestinationID
	) {}

	/// Creates a new instance
	public init() {}

	/// Creates a new instance with instance-specific override for creating a new controller
	///
	/// Default implementation is suitable for most controllers, however if you have a controller which
	/// doesn't have a custom init you'll have to use this method or if you have a base controller that
	/// requires custom init it'll be beneficial for you to create a custom subclass of StackDestination
	/// and override it's `initController` class method, you can find an example in tests.
	///
	/// - Parameters:
	///   - initControllerOverride:
	///   This override has the highest priority when creating a new controller, default one is just `Controller()`
	///   **which can lead to crashes if controller doesn't have an empty init**.
	///   *Consider using `DestinationInitializableControllerProtocol` if possible instead of this parameter*
	@inlinable
	public convenience init(_ initControllerOverride: @escaping (DestinationID) -> Controller) {
		self.init()
		self.overrideInitController(with: initControllerOverride)
	}

	@_spi(Internals)
	@inlinable
	public func _initControllerIfNeeded(
		for id: DestinationID
	) -> CocoaViewController {
		return self[id]
	}

	@_spi(Internals)
	@inlinable
	open func _invalidate(_ id: DestinationID) {
		self._controllers.removeValue(forKey: id)
	}

	/// Returns `wrappedValue[id]` if present, intializes and configures a new instance otherwise
	public subscript(_ id: DestinationID) -> Controller {
		let controller = wrappedValue[id] ?? {
			let controller = _initControllerOverride?(id) ?? Self.initController(for: id)
			_controllers[id] = controller
			configureController(controller, for: id)
			_configuration?(controller, id)
			return controller
		}()

		return controller
	}
}
#endif
