import _ComposableArchitecture
import SwiftUI
import AppModels
import TweetsListFeature
import UserSettingsFeature

public struct CurrentUserProfileView: ComposableView {
	let store: StoreOf<CurrentUserProfileFeature>

	public init(_ store: StoreOf<CurrentUserProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			headerView
				.padding(.vertical, 32)
			Divider()
				.padding(.bottom, 32)
			tweetsView
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
		}
	}

	@ViewBuilder
	var tweetsView: some View {
		LazyVStack(spacing: 32) {
			ForEachStore(
				store.scope(
					state: \.tweetsList.tweets,
					action: \.tweetsList.tweets
				),
				content: { store in
					Text(store.text)
						.padding(.horizontal)
						.contentShape(Rectangle())
						.onTapGesture {
							store.send(.tap)
						}
				}
			)
		}
	}
}

#Preview {
	NavigationStack {
		CurrentUserProfileView(Store(
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
			reducer: CurrentUserProfileFeature.init
		))
	}
}
