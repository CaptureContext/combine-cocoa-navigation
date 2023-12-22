import _ComposableArchitecture
import SwiftUI

public struct TweetDetailView: ComposableView {
	let store: StoreOf<TweetDetailFeature>

	public init(_ store: StoreOf<TweetDetailFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 24) {
				TweetView(store.scope(
					state: \.source,
					action: \.source
				))
				HStack(spacing: 0) {
					if !store.replies.tweets.isEmpty {
						RoundedRectangle(cornerRadius: 1, style: .circular)
							.fill(Color(.label).opacity(0.3))
							.frame(maxWidth: 2, maxHeight: .infinity)
					}
					TweetsListView(store.scope(
						state: \.replies,
						action: \.replies
					))
					.padding(.top)
				}
				.padding(.leading)
			}
		}
	}
}

#Preview {
	TweetDetailView(Store(
		initialState: .init(
			source: .mock(),
			replies: .init(tweets: [
				.mock(),
				.mock()
			])
		),
		reducer: TweetDetailFeature.init
	))
}
