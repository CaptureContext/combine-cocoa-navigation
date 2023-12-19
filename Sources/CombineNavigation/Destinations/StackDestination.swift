#if canImport(UIKit) && !os(watchOS)
import Capture
import CocoaAliases
import Combine
import FoundationExtensions

/// Wrapper for creating and accessing managed navigation stack controllers
@propertyWrapper
open class StackDestination<
	StackElementID: Hashable,
	Controller: CocoaViewController
>: Weakifiable {
	private var _controllers: [StackElementID: Weak<Controller>] = [:]

	open var wrappedValue: [StackElementID: Controller] {
		let controllers = _controllers.compactMapValues(\.wrappedValue)
		_controllers = controllers.mapValues(Weak.init(wrappedValue:))
		return controllers
	}

	open var projectedValue: StackDestination<StackElementID, Controller> { self }

	private var _initControllerOverride: ((StackElementID) -> Controller)?

	private var _configuration: ((Controller, StackElementID) -> Void)?

	/// Sets instance-specific override for creating a new controller
	///
	/// This override has the highest priority when creating a new controller
	///
	/// To disable isntance-specific override pass `nil` to this method
	public func overrideInitController(
		with closure: ((StackElementID) -> Controller)?
	) {
		_initControllerOverride = closure
	}

	/// Sets instance-specific configuration for controllers
	public func setConfiguration(
		_ closure: ((Controller, StackElementID) -> Void)?
	) {
		_configuration = closure
		closure.map { configure in
			wrappedValue.forEach { id, controller in
				configure(controller, id)
			}
		}
	}

	@_spi(Internals) open class func initController(
		for id: StackElementID
	) -> Controller {
		return Controller()
	}

	@_spi(Internals) open func configureController(
		_ controller: Controller,
		for id: StackElementID
	) {}

	/// Creates a new instance
	public init() {}

	/// Creates a new instance with instance-specific override for creating a new controller
	///
	/// This override has the highest priority when creating a new controller, default one is just `Controller()`
	/// **which can lead to crashes if controller doesn't have an empty init**
	///
	/// Default implementation is suitable for most controllers, however if you have a controller which
	/// doesn't have a custom init you'll have to use this method or if you have a base controller that
	/// requires custom init it'll be beneficial for you to create a custom subclass of StackDestination
	/// and override it's `initController` class method, you can find an example in tests.
	public convenience init(_ initControllerOverride: @escaping (StackElementID) -> Controller) {
		self.init()
		self.overrideInitController(with: initControllerOverride)
	}

	/// Returns `wrappedValue[id]` if present, intializes and configures a new instance otherwise
	public subscript(_ id: StackElementID) -> Controller {
		let controller = wrappedValue[id] ?? {
			let controller = _initControllerOverride?(id) ?? Self.initController(for: id)
			_controllers[id] = Weak(controller)
			configureController(controller, for: id)
			_configuration?(controller, id)
			return controller
		}()

		return controller
	}
}
#endif
