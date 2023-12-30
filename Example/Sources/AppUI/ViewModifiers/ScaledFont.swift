import SwiftUI

extension View {
	public func scaledFont(
		ofSize size: Double,
		weight: Font.Weight = .regular,
		design: Font.Design = .default
	) -> some View {
		return modifier(ScaledFont(
			size: size,
			weight: weight,
			design: design
		))
	}
}

private struct ScaledFont: ViewModifier {
	// tracks dynamic font size changes
	@Environment(\.sizeCategory)
	private var sizeCategory

	private var size: Double
	private var weight: Font.Weight
	private var design: Font.Design

	init(
		size: Double,
		weight: Font.Weight,
		design: Font.Design
	) {
		self.size = size
		self.weight = weight
		self.design = design
	}

	public func body(content: Content) -> some View {
		return content.font(.system(
			size: UIFontMetrics.default.scaledValue(for: size),
			weight: weight,
			design: design
		))
	}
}
