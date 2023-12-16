import SwiftUI
import ComposableArchitecture

public struct TweetDetailView: View {
	let store: StoreOf<TweetDetailFeature>

	public init(_ store: StoreOf<TweetDetailFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 24) {
				TweetView(store.scope(
					state: \.source,
					action: { .source($0) }
				))
				HStack(spacing: 0) {
					WithViewStore(store, observe: \.replies.isEmpty) { isEmpty in
						if !isEmpty.state {
							RoundedRectangle(cornerRadius: 1, style: .circular)
								.fill(Color(.label).opacity(0.3))
								.frame(maxWidth: 2, maxHeight: .infinity)
						}
					}
					TweetsListView(store.scope(
						state: \.replies,
						action: { .replies($0) }
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
			replies: [
				.mock(),
				.mock()
			]
		),
		reducer: TweetDetailFeature.init
	))
}