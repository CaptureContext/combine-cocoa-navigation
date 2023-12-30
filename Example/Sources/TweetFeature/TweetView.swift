import _ComposableArchitecture
import SwiftUI
import AppUI

public struct TweetView: ComposableView {
	private let store: StoreOf<TweetFeature>

	@Environment(\.colorTheme)
	var color

	private let dateFormatter = DateFormatter { $0
		.dateStyle(.short)
	}

	public init(_ store: StoreOf<TweetFeature>) {
		self.store = store
	}

	public var body: some View {
		_body
			.scaledFont(ofSize: 14)
			.padding(.horizontal)
			.background(
				color(\.background.primary)
					.onTapGesture {
						store.send(.tap)
					}
		)
	}

	@ViewBuilder
	private var _body: some View {
		HStack(alignment: .top) {
			makeAvatar(store.author.avatarURL)
			VStack(alignment: .leading, spacing: 7) {
				makeHeader(
					displayName: store.author.displayName,
					username: store.author.username,
					creationDate: store.createdAt
				)
				makeContent(store.text)
				GeometryReader { proxy in
					HStack(spacing: 0) {
						makeButton(
							systemIcon: "message",
							tint: color(\.label.secondary),
							counter: store.repliesCount,
							action: .reply
						)
						.frame(width: proxy.size.width / 6, alignment: .leading)
						makeButton(
							systemIcon: store.isLiked ? "heart.fill" : "heart",
							tint: store.isLiked ? color(\.like) : color(\.label.secondary),
							counter: store.likesCount,
							action: .toggleLike
						)
						.frame(width: proxy.size.width / 3, alignment: .center)
						makeButton(
							systemIcon: "arrow.2.squarepath",
							tint: store.isReposted ? color(\.done) : color(\.label.secondary),
							counter: store.repostsCount,
							action: .repost
						)
						.frame(width: proxy.size.width / 3, alignment: .center)
						makeButton(
							systemIcon: "square.and.arrow.up",
							tint: color(\.label.secondary),
							action: .share
						)
						.frame(width: proxy.size.width / 6, alignment: .trailing)
					}
				}
				.frame(height: 18)
			}
		}
	}

	@ViewBuilder
	private func makeAvatar(
		_ avatarURL: URL?
	) -> some View {
		Circle() // Avatar
			.stroke(color(\.label.secondary).opacity(0.3))
			.frame(width: 44, height: 44)
			.contentShape(Rectangle())
			.onTapGesture {
				store.send(.tapOnAuthor)
			}
	}

	@ViewBuilder
	private func makeHeader(
		displayName: String,
		username: String,
		creationDate: Date
	) -> some View {
		HStack {
			if displayName.isNotEmpty {
				Text(displayName)
					.fontWeight(.bold)
					.foregroundStyle(color(\.label))
					.layoutPriority(2)
				Text("@" + username.lowercased())
			} else {
				Text("@" + username.lowercased())
					.fontWeight(.bold)
					.foregroundStyle(color(\.label))
					.layoutPriority(2)
			}
			Text("• \(dateFormatter.string(from: creationDate))")
				.layoutPriority(1)
		}
		.foregroundStyle(color(\.label.secondary))
		.fontWeight(.light)
		.lineLimit(1)
	}

	@ViewBuilder
	private func makeContent(
		_ text: String
	) -> some View {
		Text(text)
			.foregroundStyle(color(\.label))
	}

	@ViewBuilder
	private func makeButton(
		systemIcon: String,
		tint: Color,
		counter: Int? = nil,
		action: Action
	) -> some View {
		Button(action: { store.send(action) }) {
			HStack(spacing: 4) {
				Image(systemName: systemIcon)

				if let counter, counter > 0 {
					Text(counter.description)
						.scaledFont(ofSize: 12)
						.transition(.scale)
				}
			}
		}
		.tint(tint)
		.foregroundStyle(tint)
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
