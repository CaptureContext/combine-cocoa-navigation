import _ComposableArchitecture
import UIKit
import SwiftUI
import Combine
import CombineExtensions
import Capture
import CombineNavigation

@RoutingController
public final class TweetDetailController: ComposableViewControllerOf<TweetDetailFeature> {
	let host = ComposableHostingController<TweetDetailView>(rootView: nil)

	@ComposableTreeDestination
	var detailController: TweetDetailController?

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

		_detailController.setStore(store?.scope(
			state: \.detail,
			action: \.detail.presented
		))
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		navigationDestination(
			isPresented: \.detail.isNotNil,
			destination: $detailController,
			popAction: .detail(.dismiss)
		)
		.store(in: &cancellables)
	}
}
