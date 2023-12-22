import _ComposableArchitecture
import SwiftUI

public struct UserProfileView: ComposableView {
	let store: StoreOf<UserProfileFeature>

	public init(_ store: StoreOf<UserProfileFeature>) {
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
			Text("@" + store.model.user.username.lowercased())
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
		UserProfileView(Store(
			initialState: .init(
				model: .mock(),
				tweetsList: .init(tweets: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				])
			),
			reducer: UserProfileFeature.init
		))
	}
}
