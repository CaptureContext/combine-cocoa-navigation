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

	@ComposablePresentationDestination(container: .navigation.container { $0
		.modalPresentationStyle(.fullScreen)
	})
	var tweetReplyController: ComposableHostingController<TweetReplyView>?

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

		_tweetReplyController.setStore(store?.scope(
			state: \.presentationDestination?.tweetReply,
			action: \.presentationDestination.tweetReply
		))

		_detailController.setStore(store?.scope(
			state: \.navigationDestination?.detail,
			action: \.navigationDestination.detail
		))
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		presentationDestination(
			isPresented: \.presentationDestination[case: \.tweetReply].isNotNil,
			destination: $tweetReplyController,
			dismissAction: .presentationDestination(.dismiss)
		)
		.store(in: &cancellables)

		navigationDestination(
			state: \.$navigationDestination,
			switch: { destinations, route in
				switch route {
				case .detail:
					destinations.$detailController
				}
			},
			popAction: .navigationDestination(.dismiss)
		)
		.store(in: &cancellables)
	}
}
