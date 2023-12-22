import _ComposableArchitecture
import SwiftUI

public struct TweetsListView: ComposableView {
	let store: StoreOf<TweetsListFeature>

	public init(_ store: StoreOf<TweetsListFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 24) {
				ForEachStore(
					store.scope(
						state: \.tweets,
						action: \.tweets
					),
					content: TweetView.init
				)
			}
		}
	}
}

#Preview {
	NavigationStack {
		TweetsListView(Store(
			initialState: .init(tweets: [
				.mock(),
				.mock()
			]),
			reducer: TweetsListFeature.init
		))
		.navigationTitle("Preview")
	}
}
