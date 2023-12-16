import SwiftUI
import ComposableArchitecture

public struct TweetView: View {
	let store: StoreOf<TweetFeature>

	public init(_ store: StoreOf<TweetFeature>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(store, observe: { $0 }) { viewStore in
			VStack(alignment: .leading, spacing: 14) {
				HStack(spacing: 16) {
					Circle() // Avatar
						.fill(Color(.label).opacity(0.3))
						.frame(width: 54, height: 54)
					Text("@" + viewStore.author.username.lowercased()).bold()
					Spacer()
				}
				.contentShape(Rectangle())
				.onTapGesture {
					viewStore.send(.tapOnAuthor)
				}
				Text(viewStore.text)
					.onTapGesture {
						viewStore.send(.tap)
					}
			}
			.padding(.horizontal)
			.background(
				Color(.systemBackground)
					.onTapGesture {
						viewStore.send(.tap)
					}
			)
		}
	}
}

#Preview {
	TweetView(Store(
		initialState: .mock(),
		reducer: TweetFeature.init
	))
}
