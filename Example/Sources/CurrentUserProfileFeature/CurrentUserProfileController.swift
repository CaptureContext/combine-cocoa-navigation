import _ComposableArchitecture
import SwiftUI
import CocoaExtensions
import CombineExtensions
@_spi(Internals) import CombineNavigation
import TweetsListFeature
import TweetReplyFeature
import UserSettingsFeature
@_spi(Internals) import ComposableExtensions

@RoutingController
public final class CurrentUserProfileController: ComposableHostingController<CurrentUserProfileView> {
	@ComposableTreeDestination
	var userSettingsController: UserSettingsController?

	var cancellable: AnyCancellable?
	#warning("Add avatarPreviewController presentation destination")

	public override func scope(_ store: Store?) {
    print("didsetstore (toNil: \(store.isNil))")
		super.scope(store)

		_userSettingsController.setStore(store?.scope(
			state: \.navigationDestination?.userSettings,
			action: \.navigationDestination.userSettings
		))
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		let cancellable = store?.publisher.sinkEvents { event in
			switch event {
			case .value: print("drv")
			case .finished: print("drf")
			}
		}
		self.cancellable = .init {
			cancellable?.cancel()
			print("drc")
		}

		navigationDestination(
			state: \.$navigationDestination,
			switch: { destinations, route in
				switch route {
				case .userSettings:
					destinations.$userSettingsController
				}
			},
			popAction: .navigationDestination(.dismiss)
		)
		.store(in: &cancellables)
	}
}
