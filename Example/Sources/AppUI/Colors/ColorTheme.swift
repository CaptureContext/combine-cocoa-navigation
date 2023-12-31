import UIKit
import SwiftUI

public struct ColorTheme {
	public struct ColorSet3 {
		public let primary: UIColor
		public let secondary: UIColor
		public let tertiary: UIColor

		public init(
			primary: UIColor,
			secondary: UIColor,
			tertiary: UIColor
		) {
			self.primary = primary
			self.secondary = secondary
			self.tertiary = tertiary
		}
	}

	public struct ColorSet4 {
		public let primary: UIColor
		public let secondary: UIColor
		public let tertiary: UIColor
		public let quaternary: UIColor

		public init(
			primary: UIColor,
			secondary: UIColor,
			tertiary: UIColor,
			quaternary: UIColor
		) {
			self.primary = primary
			self.secondary = secondary
			self.tertiary = tertiary
			self.quaternary = quaternary
		}
	}

	public let accent: UIColor
	public let like: UIColor
	public let done: UIColor

	public let label: ColorSet4
	public let background: ColorSet3

	public func callAsFunction(_ keyPath: KeyPath<ColorTheme, ColorSet3>) -> Color {
		Color(self[keyPath: keyPath.appending(path: \.primary)])
	}

	public func callAsFunction(_ keyPath: KeyPath<ColorTheme, ColorSet4>) -> Color {
		Color(self[keyPath: keyPath.appending(path: \.primary)])
	}

	public func callAsFunction(_ keyPath: KeyPath<ColorTheme, UIColor>) -> Color {
		Color(self[keyPath: keyPath])
	}
}

extension ColorTheme {
	#warning("Find a way to update current value for SUI and Cocoa")
	public static var current: ColorTheme {
		// Won't be updated in Cocoa
		Environment(\.colorTheme).wrappedValue
	}

	public static let system: Self = .init(
		accent: .systemBlue,
		like: .systemRed,
		done: .systemGreen,
		label: .init(
			primary: .label,
			secondary: .secondaryLabel,
			tertiary: .tertiaryLabel,
			quaternary: .quaternaryLabel
		),
		background: .init(
			primary: .systemBackground,
			secondary: .secondarySystemBackground,
			tertiary: .tertiarySystemBackground
		)
	)

	public static let systemTweaked: Self = .init(
		accent: .systemBlue,
		like: .systemRed,
		done: .systemGreen,
		label: .init(
			primary: .label,
			secondary: .label.withAlphaComponent(0.7),
			tertiary: .tertiaryLabel,
			quaternary: .quaternaryLabel
		),
		background: .init(
			primary: .systemBackground,
			secondary: .secondarySystemBackground,
			tertiary: .tertiarySystemBackground
		)
	)

	public static func dynamic(
		light: ColorTheme,
		dark: ColorTheme
	) -> ColorTheme {
		func color(for keyPath: KeyPath<ColorTheme, UIColor>) -> UIColor {
			UIColor { traits in
				traits.userInterfaceStyle == .dark
				? dark[keyPath: keyPath]
				: light[keyPath: keyPath]
			}
		}

		return .init(
			accent: color(for: \.accent),
			like: color(for: \.like),
			done: color(for: \.done),
			label: .init(
				primary: color(for: \.label.primary),
				secondary: color(for: \.label.secondary),
				tertiary: color(for: \.label.tertiary),
				quaternary: color(for: \.label.quaternary)
			),
			background: .init(
				primary: color(for: \.background.primary),
				secondary: color(for: \.background.secondary),
				tertiary: color(for: \.background.tertiary)
			)
		)
	}
}

// MARK: - Environment

extension EnvironmentValues {
	public var colorTheme: ColorTheme {
		get { self[ColorTheme.self] }
		set { self[ColorTheme.self] = newValue}
	}
}

extension ColorTheme: EnvironmentKey {
	public static var defaultValue: Self { .systemTweaked }
}

