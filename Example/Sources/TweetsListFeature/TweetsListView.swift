import _ComposableArchitecture
import SwiftUI
import TweetFeature

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
				TweetFeature.State(
					id: .init(),
					replyTo: nil,
					repliesCount: 12,
					isLiked: true,
					likesCount: 69,
					isReposted: false,
					repostsCount: 0,
					author: .init(
						id: .init(),
						avatarURL: nil,
						username: "capturecontext"
					),
					text: "Hello, First World!"
				),
				TweetFeature.State(
					id: .init(),
					replyTo: nil,
					repliesCount: 0,
					isLiked: true,
					likesCount: 420,
					isReposted: false,
					repostsCount: 1,
					author: .init(
						id: .init(),
						avatarURL: nil,
						username: "capturecontext"
					),
					text: "Hello, Second World!"
				)
			]),
			reducer: TweetsListFeature.init
		))
		.navigationTitle("Preview")
	}
}
