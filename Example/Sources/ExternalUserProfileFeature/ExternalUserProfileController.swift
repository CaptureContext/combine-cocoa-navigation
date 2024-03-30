import _ComposableArchitecture
import SwiftUI
import CocoaExtensions
import CombineExtensions
import CombineNavigation
import TweetsListFeature
import TweetReplyFeature
import UserSettingsFeature

@RoutingController
public final class ExternalUserProfileController: ComposableHostingController<ExternalUserProfileView> {

	#warning("Add avatarPreviewController presentation destination")

	public override func scope(_ store: Store?) {
		super.scope(store)
	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {

	}
}
