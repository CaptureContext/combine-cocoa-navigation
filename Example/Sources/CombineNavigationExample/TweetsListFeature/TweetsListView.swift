import SwiftUI
import ComposableArchitecture

public struct TweetsListView: View {
	let store: StoreOf<TweetsListFeature>

	public init(_ store: StoreOf<TweetsListFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 24) {
				ForEachStore(
					store.scope(
						state: { $0 },
						action: { .tweets($0) }
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
			initialState: [
				.mock(),
				.mock()
			],
			reducer: TweetsListFeature.init
		))
		.navigationTitle("Preview")
	}
}
