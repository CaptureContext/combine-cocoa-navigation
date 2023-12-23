public protocol ArrayBuilderProtocol<Element> {
	associatedtype Element

	static func buildExpression(_ component: Element) -> [Element]

	static func buildExpression(_ components: [Element]) -> [Element]

	static func buildBlock(_ components: Element...) -> [Element]

	static func buildArray(_ components: [[Element]]) -> [Element]

	static func buildPartialBlock(first: [Element]) -> [Element]

	static func buildPartialBlock(accumulated: [Element], next: [Element]) -> [Element]

	static func buildOptional(_ component: [Element]?) -> [Element]

	static func buildEither(first component: [Element]) -> [Element]

	static func buildEither(second component: [Element]) -> [Element]

	static func buildLimitedAvailability(_ component: [Element]) -> [Element]
}

extension ArrayBuilderProtocol {
	public static func buildExpression(_ component: Element) -> [Element] {
		[component]
	}

	public static func buildExpression(_ components: [Element]) -> [Element] {
		components
	}

	public static func buildBlock(_ components: Element...) -> [Element] {
		components
	}

	public static func buildArray(_ components: [[Element]]) -> [Element] {
		components.flatMap { $0 }
	}

	public static func buildPartialBlock(first: [Element]) -> [Element] {
		first
	}

	public static func buildPartialBlock(accumulated: [Element], next: [Element]) -> [Element] {
		accumulated + next
	}

	public static func buildOptional(_ component: [Element]?) -> [Element] {
		component ?? []
	}

	public static func buildEither(first component: [Element]) -> [Element] {
		component
	}

	public static func buildEither(second component: [Element]) -> [Element] {
		component
	}

	public static func buildLimitedAvailability(_ component: [Element]) -> [Element] {
		component
	}
}
