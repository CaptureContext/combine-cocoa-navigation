import SwiftUI
import ComposableArchitecture

public struct UserProfileView: View {
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
				state: \.tweets,
				action: { .tweetsList($0) }
			))
		}
	}

	@ViewBuilder
	var headerView: some View {
		VStack(spacing: 24) {
			WithViewStore(store, observe: \.model.user.avatarURL) { viewStore in
				Circle()
					.fill(Color(.label).opacity(0.3))
					.frame(width: 86, height: 86)
					.onTapGesture {
						viewStore.send(.tapOnAvatar)
					}
			}
			WithViewStore(store, observe: \.model.user.username) { viewStore in
				Text("@" + viewStore.state.lowercased())
					.monospaced()
					.bold()
			}
			WithViewStore(store, observe: \.model.isFollowedByYou) { viewStore in
				Button(action: { viewStore.send(.tapFollow) }) {
					Text(viewStore.state ? "Unfollow" : "Follow")
				}
			}
		}
	}
}

#Preview {
	NavigationStack {
		UserProfileView(Store(
			initialState: .init(
				model: .mock(),
				tweets: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				]
			),
			reducer: UserProfileFeature.init
		))
	}
}
