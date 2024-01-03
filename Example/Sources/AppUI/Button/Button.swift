#if os(iOS)
import CocoaAliases
import CocoaExtensions
import DeclarativeConfiguration
import Capture

extension CustomButton where Content == UILabel {
	public func enable() {
		isEnabled = true
	}
	
	public func disable() {
		isEnabled = false
	}
}

extension UIView {
	public func pinToSuperview() {
		guard let superview = superview else { return }
		translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			topAnchor.constraint(equalTo: superview.topAnchor),
			bottomAnchor.constraint(equalTo: superview.bottomAnchor),
			leadingAnchor.constraint(equalTo: superview.leadingAnchor),
			trailingAnchor.constraint(equalTo: superview.trailingAnchor)
		])
	}
}

public final class CustomButton<Content: CocoaView>: CocoaView {
	
	// MARK: - Properties
	
	private let control = Control()
	
	public let content: Content
	
	public let overlay = UIView {
		$0
			.backgroundColor(.clear)
			.alpha(0)
	}
	
	public var pressStartAnimationProvider: UIViewPropertyAnimatorProvider?
	public var pressEndAnimationProvider: UIViewPropertyAnimatorProvider? = .init(
		duration: 0.4,
		curve: .easeOut
	)
	private var pressStartAnimatior: UIViewPropertyAnimator?
	private var pressEndAnimatior: UIViewPropertyAnimator?
	
	private var contentPressResettable: Resettable<Content>!
	private var contentDisableResettable: Resettable<Content>!
	
	private var overlayPressResettable: Resettable<UIView>!
	private var overlayDisableResettable: Resettable<UIView>!
	
	public var pressStyle: StyleManager<PressConfiguration> = .default
	public var disabledStyle: StyleManager<DisableConfiguration> = .default
	
	public var tapAreaOffset: UIEdgeInsets = .init(all: 8)
	
	public var haptic: HapticFeedback? {
		get { control.haptic }
		set { control.haptic = newValue }
	}
	
	public var action: (() -> Void)? {
		get {
			control.$onAction.map { action in
				{ action(()) }
			}
		}
		set {
			onAction(perform: newValue)
		}
	}
	
	private var _isEnabled = true
	public var isEnabled: Bool {
		get { _isEnabled }
		set {
			_isEnabled = newValue
			isUserInteractionEnabled = newValue
			if !isEnabled {
				pressEndAnimatior?.stopAnimation(true)
				pressEndAnimatior?.finishAnimation(at: .current)
			}
			disabledStyle.updateStyle(
				for: DisableConfiguration(
					isEnabled: newValue,
					content: contentDisableResettable,
					overlay: overlayDisableResettable
				)
			)
		}
	}
	
	@PropertyProxy(\CustomButton.control.isEnabled)
	public var isControlEnabled: Bool
	
	// MARK: - Initialization
	
	public convenience init(action: @escaping () -> Void = {}, content: () -> Content) {
		self.init(content: content(), action: action)
	}
	
	public convenience init(action: @escaping () -> Void) {
		self.init(content: .init(), action: action)
	}
	
	public convenience init() {
		self.init(frame: .zero)
		self.configure()
	}
	
	public init(content: Content, action: @escaping () -> Void = {}) {
		self.content = content
		super.init(frame: .zero)
		self.control.onAction(perform: action)
		self.configure()
	}
	
	public override init(frame: CGRect) {
		self.content = .init()
		super.init(frame: frame)
		configure()
	}
	
	public required init?(coder: NSCoder) {
		self.content = .init()
		super.init(coder: coder)
		configure()
	}
	
	deinit {
		[pressStartAnimatior, pressEndAnimatior].forEach { animator in
			animator?.stopAnimation(true)
			animator?.finishAnimation(at: .current)
		}
		// swiftlint:disable:next unused_capture_list
		DispatchQueue.main.async { [pressStartAnimatior, pressEndAnimatior] in }
	}
	
	// MARK: - Hit test
	
	public override func point(
		inside point: CGPoint,
		with event: UIEvent?
	) -> Bool {
		return CGRect(
			x: bounds.origin.x - tapAreaOffset.left,
			y: bounds.origin.y - tapAreaOffset.top,
			width: bounds.width + tapAreaOffset.left + tapAreaOffset.right,
			height: bounds.height + tapAreaOffset.top + tapAreaOffset.bottom
		).contains(point)
	}
	
	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		guard let view = super.hitTest(point, with: event)
		else { return nil }
		
		if view === self { return control }
		return view
	}
	
	// MARK: Initial configuration
	
	private func configure() {
		content.removeFromSuperview()
		control.removeFromSuperview()
		
		setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
		
		addSubview(content)
		addSubview(overlay)
		addSubview(control)
		
		content.pinToSuperview()
		overlay.pinToSuperview()
		control.pinToSuperview()
		
		contentPressResettable = Resettable(content)
		contentDisableResettable = Resettable(content)
		
		overlayPressResettable = Resettable(overlay)
		overlayDisableResettable = Resettable(overlay)
		
		control.onPressBegin { [weak self] in
			self?.animatePressBegin()
		}
		
		control.onPressEnd { [weak self] in
			self?.animatePressEnd()
		}
	}
	
	public override func layoutSubviews() {
		content.frame = bounds
		content.layoutIfNeeded()
		overlay.frame = bounds
		overlay.layoutIfNeeded()
		control.frame = bounds
	}
	
	@discardableResult
	public func onAction(perform action: (() -> Void)?) -> CustomButton {
		control.onAction(
			perform: action.map { action in
				{ _ in action() }
			}
		)
		return self
	}
	
	@discardableResult
	public func appendAction(_ action: @escaping () -> Void) -> CustomButton {
		control.onAction(
			perform: control.$onAction.map { oldAction in
				return { _ in
					oldAction(())
					action()
				}
			}
		)
		return self
	}
	
	@discardableResult
	public func prependAction(_ action: @escaping () -> Void) -> CustomButton {
		control.onAction(
			perform: control.$onAction.map { oldAction in
				return { _ in
					action()
					oldAction(())
				}
			}
		)
		return self
	}
	
	@discardableResult
	public func onInternalAction(perform action: (() -> Void)?) -> CustomButton {
		control.onInternalAction(
			perform: action.map { action in
				{ _ in action() }
			}
		)
		return self
	}
	
	@discardableResult
	public func modifier(_ modifier: StyleModifier) -> CustomButton {
		modifier.config.configured(self)
	}
	
	@discardableResult
	public func pressStyle(_ styleManager: StyleManager<PressConfiguration>) -> CustomButton {
		builder.pressStyle(styleManager).build()
	}
	
	@discardableResult
	public func disabledStyle(_ styleManager: StyleManager<DisableConfiguration>) -> CustomButton {
		builder.disabledStyle(styleManager).build()
	}
	
	@discardableResult
	public func tapAreaOffset(_ size: CGSize) -> CustomButton {
		return tapAreaOffset(
			.init(
				horizontal: size.width,
				vertical: size.height
			)
		)
	}
	
	@discardableResult
	public func tapAreaOffset(_ offset: UIEdgeInsets) -> CustomButton {
		builder.tapAreaOffset(offset).build()
	}
	
	@discardableResult
	public func haptic(_ haptic: HapticFeedback) -> CustomButton {
		builder.haptic(haptic).build()
	}
	
	@discardableResult
	public func pressStartAnimator(_ provider: UIViewPropertyAnimatorProvider?) -> CustomButton {
		builder.pressStartAnimationProvider(provider).build()
	}
	
	@discardableResult
	public func pressEndAnimator(_ provider: UIViewPropertyAnimatorProvider?) -> CustomButton {
		builder.pressEndAnimationProvider(provider).build()
	}
	
	// MARK: Animation
	
	private func animatePressBegin() {
		pressEndAnimatior?.stopAnimation(true)
		pressStartAnimatior?.stopAnimation(true)
		let animation = capture { _self in
			_self.pressStyle.updateStyle(
				for: PressConfiguration(
					isPressed: true,
					content: _self.contentPressResettable,
					overlay: _self.overlayPressResettable
				)
			)
		}
		if let provider = pressStartAnimationProvider {
			pressStartAnimatior = provider.makePropertyAnimator(for: animation)
			pressStartAnimatior?.startAnimation()
		} else {
			animation()
		}
	}
	
	private func animatePressEnd() {
		if pressStartAnimatior?.isRunning == true {
			pressStartAnimatior?.addCompletion { position in
				self.forceAnimatePressEnd()
			}
			return
		}
		forceAnimatePressEnd()
	}
	
	private func forceAnimatePressEnd() {
		pressStartAnimatior?.stopAnimation(false)
		let animation = capture { _self in
			_self.pressStyle.updateStyle(
				for: PressConfiguration(
					isPressed: false,
					content: _self.contentPressResettable,
					overlay: _self.overlayPressResettable
				)
			)
		}
		if let provider = pressEndAnimationProvider {
			pressEndAnimatior = provider.makePropertyAnimator(for: animation)
			pressEndAnimatior?.startAnimation()
		} else {
			animation()
		}
	}
	
	// MARK: UIControl Handler
	
	private class Control: UIControl {
		@Handler1<Void>
		var onPressBegin
		
		@Handler1<Void>
		var onPressEnd
		
		@Handler1<Void>
		var onAction
		
		@Handler1<Void>
		var onInternalAction
		
		var haptic: HapticFeedback?
		
		convenience init(
			action: @escaping () -> Void,
			onPressBegin: @escaping () -> Void,
			onPressEnd: @escaping () -> Void
		) {
			self.init()
			self.onAction(perform: action)
			self.onPressBegin(perform: onPressBegin)
			self.onPressEnd(perform: onPressEnd)
			self.configure()
		}
		
		override init(frame: CGRect) {
			super.init(frame: frame)
			configure()
		}
		
		required init?(coder: NSCoder) {
			super.init(coder: coder)
			configure()
		}
		
		private func configure() {
			addTarget(self, action: #selector(pressBegin), for: [.touchDown, .touchDragEnter])
			addTarget(
				self,
				action: #selector(pressEnd),
				for: [.touchUpInside, .touchDragExit, .touchCancel]
			)
			addTarget(self, action: #selector(runAction), for: [.touchUpInside])
		}
		
		@objc private func pressBegin() {
			_onPressBegin()
		}
		
		@objc private func pressEnd() {
			_onPressEnd()
		}
		
		@objc private func runAction() {
			_onInternalAction()
			_onAction()
			haptic?.trigger()
		}
	}
}

// MARK: - CustomButton<UILabel>

extension CustomButton where Content == UILabel {
	public convenience init(_ title: String, action: @escaping () -> Void = {}) {
		self.init(action: action) {
			UILabel { $0
				.numberOfLines(0)
				.text(title)
				.textAlignment(.center)
				.isUserInteractionEnabled(true)
			}
		}
	}
}

extension UIEdgeInsets {
	public init(all inset: CGFloat) {
		self.init(
			top: inset,
			left: inset,
			bottom: inset,
			right: inset
		)
	}
	
	public init(
		horizontal: CGFloat,
		vertical: CGFloat
	) {
		self.init(
			top: vertical,
			left: horizontal,
			bottom: vertical,
			right: horizontal
		)
	}
}

#endif
