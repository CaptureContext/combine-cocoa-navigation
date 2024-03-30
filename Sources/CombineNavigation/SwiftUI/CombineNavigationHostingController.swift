#if canImport(SwiftUI)
import CocoaExtensions
import CocoaAliases
import SwiftUI

public struct _CombineNavigationHostedView<
	Content: View
>: View {
	@_spi(Internals)
	public var content: Content?

	@_spi(Internals)
	public let parent: CocoaViewController?

	@_spi(Internals)
	public init(
		content: Content? = nil,
		parent: CocoaViewController? = nil
	) {
		self.content = content
		self.parent = parent
	}

	public var body: some View {
		content.map { content in
			content.environmentObject(
				__HostingControllerEnvironmentalContainer(parent)
			)
		}
	}
}

open class CombineNavigationHostingController<Content: View>
: CustomHostingController<_CombineNavigationHostedView<Content>> {
	public required init() {
		super.init(rootView: .init())
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	public override init(rootView: _CombineNavigationHostedView<Content>) {
		super.init(rootView: rootView)
	}

	public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(rootView: .init())
	}

	open override func _init() {
		super._init()
		self.rootView = .init(content: contentView, parent: self)
	}

	public var contentView: Content? {
		set { rootView = .init(content: newValue, parent: self) }
		_read { yield rootView.content }
		_modify { yield &rootView.content}
	}
}

#if canImport(UIKit)
extension CombineNavigationHostingController: DestinationInitializableControllerProtocol {
	public static func _init_for_destination() -> CocoaViewController {
		return Self.init()
	}
}
#endif
#endif
