import _ComposableArchitecture
import SwiftUI
import AppModels
import TweetsListFeature

public struct ExternalUserProfileView: ComposableView {
	let store: StoreOf<ExternalUserProfileFeature>

	public init(_ store: StoreOf<ExternalUserProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			headerView
				.padding(.vertical, 32)
			Divider()
				.padding(.bottom, 32)
			TweetsListView(store.scope(
				state: \.tweetsList,
				action: \.tweetsList
			))
		}
	}

	@ViewBuilder
	var headerView: some View {
		VStack(spacing: 24) {
			Circle()
				.fill(Color(.label).opacity(0.3))
				.frame(width: 86, height: 86)
				.onTapGesture {
					store.send(.tapOnAvatar)
				}
			Text("@" + store.model.username.lowercased())
				.monospaced()
				.bold()
			Button(action: { store.send(.tapFollow) }) {
				Text(store.model.isFollowedByYou ? "Unfollow" : "Follow")
			}
		}
	}
}

#Preview {
	NavigationStack {
		ExternalUserProfileView(Store(
			initialState: .init(
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
			),
			reducer: ExternalUserProfileFeature.init
		))
	}
}
