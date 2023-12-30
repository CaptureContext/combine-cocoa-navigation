import _ComposableArchitecture
import SwiftUI
import TweetFeature

public struct TweetsListView: ComposableView {
	let store: StoreOf<TweetsListFeature>

	public init(_ store: StoreOf<TweetsListFeature>) {
		self.store = store
	}

	public var body: some View {
		if store.tweets.isNotEmpty {
			ScrollView(.vertical) {
				LazyVStack(spacing: 24) {
					ForEach(store.tweets) { tweet in
						if let store = store.scope(state: \.tweets[id: tweet.id], action: \.tweets[id: tweet.id]) {
							TweetView(store)
						}
					}
				}
			}
		} else {
			ZStack {
				switch store.placeholder {
				case let .text(text):
					Text(text)
				case .activityIndicator:
					ProgressView()
				case .none:
					EmptyView()
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
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
