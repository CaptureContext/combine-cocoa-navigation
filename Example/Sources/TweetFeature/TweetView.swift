import _ComposableArchitecture
import SwiftUI

public struct TweetView: ComposableView {
	let store: StoreOf<TweetFeature>

	public init(_ store: StoreOf<TweetFeature>) {
		self.store = store
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			HStack(spacing: 16) {
				Circle() // Avatar
					.fill(Color(.label).opacity(0.3))
					.frame(width: 54, height: 54)
				Text("@" + store.author.username.lowercased()).bold()
				Spacer()
			}
			.contentShape(Rectangle())
			.onTapGesture {
				store.send(.tapOnAuthor)
			}
			Text(store.text)
				.onTapGesture {
					store.send(.tap)
				}
		}
		.padding(.horizontal)
		.background(
			Color(.systemBackground)
				.onTapGesture {
					store.send(.tap)
				}
		)
	}
}

#Preview {
	TweetView(Store(
		initialState: TweetFeature.State(
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
		reducer: TweetFeature.init
	))
}
