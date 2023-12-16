import UIKit
import SwiftUI
import ComposableArchitecture
import Combine
import CombineExtensions
import Capture
import CombineNavigation

@RoutingController
public final class TweetDetailController: ComposableViewControllerOf<TweetDetailFeature> {
	let host = UIHostingController<TweetDetailView?>(rootView: nil)

	@TreeDestination
	var detailController: TweetDetailController?

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.addChild(host)
		self.view.addSubview(host.view)
		host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		host.view.frame = view.bounds
		host.didMove(toParent: self)
	}

	public override func scope(_ store: Store?) {
		host.rootView = store.map { TweetDetailView($0) }

		_detailController.setConfiguration { controller in
			controller.setStore(store?.scope(
				state: \.detail,
				action: { .detail(.presented($0)) }
			))
		}
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		navigationDestination(
			"reply_detail",
			isPresented: publisher.detail.isNotNil,
			controller: _detailController.callAsFunction,
			onPop: captureSend(.detail(.dismiss))
		)
		.store(in: &cancellables)
	}
}