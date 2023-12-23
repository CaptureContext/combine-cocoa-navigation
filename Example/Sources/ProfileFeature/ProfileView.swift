import _ComposableArchitecture
import SwiftUI
import AppModels
import UserProfileFeature
import CurrentUserProfileFeature

public struct ProfileView: ComposableView {
	let store: StoreOf<ProfileFeature>

	public init(_ store: StoreOf<ProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		SwitchStore(store) { state in
			switch state {
			case .user:
				CaseLet(
					/ProfileFeature.State.user,
					action: ProfileFeature.Action.user,
					then: UserProfileView.init
				)
			case .currentUser:
				CaseLet(
					/ProfileFeature.State.currentUser,
					action: ProfileFeature.Action.currentUser,
					then: CurrentUserProfileView.init
				)
			}
		}
	}
}

#Preview {
	NavigationStack {
		ProfileView(Store(
			initialState: .user(.init(
				model: .mock(),
				tweetsList: .init(tweets: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				])
			)),
			reducer: ProfileFeature.init
		))
	}
}
