import _ComposableArchitecture
import UIKit
import SwiftUI
import Combine
import CombineExtensions
import Capture
import CombineNavigation

@RoutingController
public final class FeedTabController: ComposableViewController<
	FeedTabFeature.State,
	FeedTabFeature.Action
> {
	let contentController: TweetsFeedController = .init()

	@ComposableStackDestination
	var feedControllers: [StackElementID: TweetsFeedController]

	@ComposableStackDestination({ _ in .init(rootView: nil) })
	var profileControllers: [StackElementID: ComposableHostingController<ProfileView>]

	public override func viewDidLoad() {
		super.viewDidLoad()

		// For direct children this method is used instead of addChild
		self.addRoutedChild(contentController)
		self.view.addSubview(contentController.view)
		contentController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		contentController.view.frame = view.bounds
		contentController.didMove(toParent: self)
	}

	public override func scope(_ store: Store?) {
		contentController.setStore(store?.scope(
			state: \.feed,
			action: \.feed
		))

		_feedControllers.setStore { id in
			store?.scope(
				state: \.path[id: id]?.feed,
				action: \.path[id: id].feed
			)
		}

		_profileControllers.setStore { id in
			store?.scope(
				state: \.path[id: id]?.profile,
				action: \.path[id: id].profile
			)
		}
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		navigationStack(
			state: \.path,
			action: \.path,
			switch: { destinations, route in
				switch route {
				case .feed:
					destinations.$feedControllers
				case .profile:
					destinations.$profileControllers
				}
			}
		)
		.store(in: &cancellables)
	}
}
