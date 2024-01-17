#if os(iOS)
extension CustomButton {
	@discardableResult
	func applyingStyle(_ style: StyleModifier) -> CustomButton {
		style.apply(to: self)
		return self
	}
}

extension CustomButton.StyleModifier {
	public static func rounded(radius: CGFloat = 12) -> Self {
		.init {
			$0.content.layer.scope { $0
				.cornerRadius(radius)
				.masksToBounds(true)
			}
		}
	}
}
#endif
