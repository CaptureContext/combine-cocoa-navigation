import _ComposableArchitecture
import UIKit
import SwiftUI
import Combine
import CombineExtensions
import Capture
import CombineNavigation
import TweetReplyFeature

@RoutingController
public final class TweetDetailController: ComposableViewControllerOf<TweetDetailFeature> {
	let host = ComposableHostingController<TweetDetailView>()

	@ComposableTreeDestination
	var detailController: TweetDetailController?

	@ComposableViewTreeDestination<TweetReplyView>
	var tweetReplyController

	public override func viewDidLoad() {
		super.viewDidLoad()
		self.addChild(host)
		self.view.addSubview(host.view)
		host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		host.view.frame = view.bounds
		host.didMove(toParent: self)
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.store?.send(.event(.didAppear))
	}

	public override func scope(_ store: Store?) {
		host.setStore(store)

		#warning("Use present")
		_tweetReplyController.setStore(store?.scope(
			state: \.destination?.tweetReply,
			action: \.destination.presented.tweetReply
		))

		_detailController.setStore(store?.scope(
			state: \.destination?.detail,
			action: \.destination.presented.detail
		))
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		navigationDestination(
			state: \State.$destination,
			switch: { destinations, route in
				switch route {
				case .tweetReply:
					destinations.$tweetReplyController
				case .detail:
					destinations.$detailController
				}
			},
			popAction: .destination(.dismiss)
		)
		.store(in: &cancellables)
	}
}
