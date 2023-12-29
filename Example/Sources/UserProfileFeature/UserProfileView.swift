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
				model: .init(
					id: .init(),
					username: "capturecontext",
					displayName: "CaptureContext",
					bio: "SwiftData kinda sucks",
					avatarURL: nil,
					isFollowingYou: false,
					isFollowedByYou: false,
					followsCount: 69,
					followersCount: 1123927,
					tweetsCount: 1
				),
				tweetsList: .init(tweets: [
					.init(
						id: .init(),
						replyTo: nil,
						repliesCount: 3,
						isLiked: true,
						likesCount: 999,
						isReposted: false,
						repostsCount: 0,
						author: .init(
							id: .init(),
							avatarURL: nil,
							username: "capturecontext"
						),
						text: "Hello, World!"
					)
				])
			)),
			reducer: UserProfileFeature.init
		))
	}
}
