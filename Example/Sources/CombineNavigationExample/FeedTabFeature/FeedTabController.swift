import UIKit
import SwiftUI
import ComposableArchitecture
import Combine
import CombineExtensions
import Capture
import CombineNavigation

@RoutingController
public final class FeedTabController: ComposableViewControllerOf<FeedTabFeature> {
	let contentController: TweetsFeedController = .init()

	@StackDestination
	var feedControllers: [StackElementID: TweetsFeedController]

	@StackDestination({ _ in .init(rootView: nil) })
	var profileControllers: [StackElementID: UIHostingController<ProfileView.IfLetView?>]

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
			action: { .feed($0)}
		))

		_feedControllers.setConfiguration { controller, id in
			controller.setStore(store?.scope(
				state: { $0.path[id: id, case: \.feed] },
				action: { .path(.element(id: id, action: .feed($0))) }
			))
		}

		_profileControllers.setConfiguration { controller, id in
			controller.rootView = store.map { store in
				ProfileView.IfLetView(store.scope(
					state: { $0.path[id: id, case: \.profile] },
					action: { .path(.element(id: id, action: .profile($0))) }
				))
			}
		}
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		navigationStack(
			publisher.map(\.path).removeDuplicates(by: { $0.ids == $1.ids }),
			ids: \.ids,
			route: { $0[id: $1] },
			switch: destinations { destinations, route in
				switch route {
				case .feed:
					destinations.$feedControllers
				case .profile:
					destinations.$profileControllers
				}
			},
			onPop: capture { _self, ids in
				_self.sendPop(ids, from: \.path)
			}
		)
		.store(in: &cancellables)
	}
}
