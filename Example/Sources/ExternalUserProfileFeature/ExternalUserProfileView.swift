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
		ExternalUserProfileView(Store(
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
			reducer: ExternalUserProfileFeature.init
		))
	}
}
