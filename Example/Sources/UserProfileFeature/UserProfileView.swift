import _ComposableArchitecture
import SwiftUI
import AppModels
import ExternalUserProfileFeature
import CurrentUserProfileFeature

public struct UserProfileView: ComposableView {
	let store: StoreOf<UserProfileFeature>

	public init(_ store: StoreOf<UserProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		switch store.state {
		case .external:
			store.scope(
				state: \.external,
				action: \.external
			)
			.map(ExternalUserProfileView.init)
		case .current:
			store.scope(
				state: \.current,
				action: \.current
			)
			.map(CurrentUserProfileView.init)
		}
	}
}

#Preview {
	NavigationStack {
		UserProfileView(Store(
			initialState: .external(.init(
				model: .mock(),
				tweetsList: .init(tweets: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				])
			)),
			reducer: UserProfileFeature.init
		))
	}
}
