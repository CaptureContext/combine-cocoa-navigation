import SwiftUI
import ComposableArchitecture

public struct CurrentUserProfileView: View {
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
			WithViewStore(store, observe: \.model.avatarURL) { viewStore in
				Circle()
					.fill(Color(.label).opacity(0.3))
					.frame(width: 86, height: 86)
					.onTapGesture {
						viewStore.send(.tapOnAvatar)
					}
			}
			WithViewStore(store, observe: \.model.username) { viewStore in
				Text("@" + viewStore.state.lowercased())
					.monospaced()
					.bold()
			}
		}
	}

	@ViewBuilder
	var tweetsView: some View {
		LazyVStack(spacing: 32) {
			ForEachStore(
				store.scope(
					state: \.tweets,
					action: { .tweetsList(.tweets($0)) }
				),
				content: { store in
					WithViewStore(store, observe: \.text) { viewStore in
						Text(viewStore.state)
							.padding(.horizontal)
							.contentShape(Rectangle())
							.onTapGesture {
								viewStore.send(.tap)
							}
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
				tweets: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				]
			),
			reducer: CurrentUserProfileFeature.init
		))
	}
}
