import _ComposableArchitecture
import SwiftUI
import AppModels
import TweetFeature
import TweetsListFeature

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
			source: TweetFeature.State(
				id: .init(),
				replyTo: nil,
				repliesCount: 3,
				isLiked: true,
				likesCount: 999,
				isReposted: false,
				repostsCount: 0,
				author: .init(
					id: .init(),
					avatarURL: nil,
					username: "capturecontext"
				),
				text: "Hello, World!"
			),
			replies: .init(tweets: [
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
			])
		),
		reducer: TweetDetailFeature.init
	))
}
