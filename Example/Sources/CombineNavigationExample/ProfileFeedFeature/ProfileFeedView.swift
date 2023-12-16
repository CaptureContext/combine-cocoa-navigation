import SwiftUI
import ComposableArchitecture

public struct ProfileFeedView: View {
	let store: StoreOf<ProfileFeedFeature>

	public init(_ store: StoreOf<ProfileFeedFeature>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 24) {
				ForEachStore(
					store.scope(
						state: \.items,
						action: { .items($0) }
					),
					content: TweetView.init
				)
			}
		}
	}
}

#Preview {
	NavigationStack {
		ProfileFeedView(Store(
			initialState: .init(
				items: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				]
			),
			reducer: ProfileFeedFeature.init
		))
	}
}
