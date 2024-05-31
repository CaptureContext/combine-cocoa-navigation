#if canImport(SwiftUI)
//
// Copyright (c) Vatsal Manot
// https://github.com/SwiftUIX/SwiftUIX
//

import SwiftUI
import CocoaAliases

extension View {
	public typealias HostingParent = __EnvironmentalContainerAccessor<CocoaViewController>
}

internal class __HostingControllerEnvironmentalContainer: ObservableObject {
	let content: CocoaViewController?

	init(_ content: CocoaViewController?) {
		self.content = content
	}
}

@propertyWrapper
public class __EnvironmentalContainerAccessor<Content>: DynamicProperty {
	@EnvironmentObject
	private var _wrappedValue: __HostingControllerEnvironmentalContainer

	public var wrappedValue: Content? {
		__wrappedValue._isPresent ? (_wrappedValue.content as? Content) : nil
	}

	public init() {}
}

extension EnvironmentObject {
	fileprivate var _isPresent: Bool {
		let mirror = Mirror(reflecting: self)
		let _store = mirror.children.first(where: { $0.label == "_store" })

		guard let _store else { return false }

		return (_store.value as? ObjectType) != nil
	}
}
#endif
