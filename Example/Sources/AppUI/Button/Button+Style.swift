#if os(iOS)
import CocoaAliases
import LocalExtensions

extension CustomButton {
	public struct StyleModifier {
		public let config: Config

		public init(_ config: (Config) -> Config) {
			self.init(Config(config: config))
		}

		public init(_ config: Config) {
			self.config = config
		}

		public func apply(to button: CustomButton) {
			config.configure(button)
		}
	}

	public struct DisableConfiguration {
		internal init(
			isEnabled: Bool,
			content: Resettable<Content>,
			overlay: Resettable<UIView>
		) {
			self.isEnabled = isEnabled
			self.content = content
			self.overlay = overlay
		}

		public let isEnabled: Bool
		public let content: Resettable<Content>
		public let overlay: Resettable<UIView>
	}

	public struct PressConfiguration {
		internal init(
			isPressed: Bool,
			content: Resettable<Content>,
			overlay: Resettable<UIView>
		) {
			self.isPressed = isPressed
			self.content = content
			self.overlay = overlay
		}

		public let isPressed: Bool
		public let content: Resettable<Content>
		public let overlay: Resettable<UIView>
	}

	public struct StyleManager<Configuration> {
		public static func custom(_ update: @escaping (Configuration) -> Void) -> StyleManager {
			return StyleManager(update: update)
		}

		private let updateStyleForConfiguration: (Configuration) -> Void

		public init(update: @escaping (Configuration) -> Void) {
			self.updateStyleForConfiguration = update
		}

		func updateStyle(for configuration: Configuration) {
			updateStyleForConfiguration(configuration)
		}
	}
}

extension CustomButton.StyleManager where Configuration == CustomButton.DisableConfiguration {
	public static var `default`: Self { .alpha(0.5) }

	public static var none: Self { .init { _ in } }

	public static func alpha(_ value: CGFloat) -> Self {
		.init { configuration in
			if configuration.isEnabled {
				configuration.content.wrappedValue.alpha = 1
			} else {
				configuration.content.wrappedValue.alpha = value
			}
		}
	}

	public static func darken(_ modifier: CGFloat) -> Self {
		.init { configuration in
			configuration.overlay.wrappedValue.backgroundColor = .black
			if configuration.isEnabled {
				configuration.overlay.wrappedValue.alpha = 0
			} else {
				configuration.overlay.wrappedValue.alpha = modifier
			}
		}
	}

	public static func lighten(_ modifier: CGFloat) -> Self {
		.init { configuration in
			configuration.overlay.wrappedValue.backgroundColor = .white
			if configuration.isEnabled {
				configuration.overlay.wrappedValue.alpha = 0
			} else {
				configuration.overlay.wrappedValue.alpha = modifier
			}
		}
	}

	public static func scale(_ modifier: CGFloat) -> Self {
		.init { configuration in
			if configuration.isEnabled {
				configuration.content.wrappedValue.transform = .identity
			} else {
				configuration.content.wrappedValue.transform = .init(scaleX: modifier, y: modifier)
			}
		}
	}
}

extension CustomButton.StyleManager where Configuration == CustomButton.PressConfiguration {
	public static var `default`: Self { .alpha(0.2) }

	public static var none: Self { .init { _ in } }

	public static func alpha(_ value: CGFloat) -> Self {
		.init { configuration in
			if configuration.isPressed {
				configuration.content.wrappedValue.alpha = value
			} else {
				configuration.content.wrappedValue.alpha = 1
			}
		}
	}

	public static func darken(_ modifier: CGFloat) -> Self {
		.init { configuration in
			configuration.overlay.wrappedValue.backgroundColor = .black
			if configuration.isPressed {
				configuration.overlay.wrappedValue.alpha = modifier
			} else {
				configuration.overlay.wrappedValue.alpha = 1
			}
		}
	}

	public static func lighten(_ modifier: CGFloat) -> Self {
		.init { configuration in
			configuration.overlay.wrappedValue.backgroundColor = .white
			if configuration.isPressed {
				configuration.overlay.wrappedValue.alpha = modifier
			} else {
				configuration.overlay.wrappedValue.alpha = 1
			}
		}
	}

	public static func scale(_ modifier: CGFloat) -> Self {
		.init { configuration in
			if configuration.isPressed {
				configuration.content.wrappedValue.transform = .init(scaleX: modifier, y: modifier)
			} else {
				configuration.content.wrappedValue.transform = .identity
			}
		}
	}
}
#endif
