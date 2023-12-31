import _ComposableArchitecture
import SwiftUI
import AppUI
import TweetFeature

public struct SimpleTweetPreviewView: ComposableView {
	private let store: Store<TweetFeature.State, Never>

	@Environment(\.colorTheme)
	var color

	private let dateFormatter = DateFormatter { $0
		.dateStyle(.short)
	}

	public init(_ store: Store<TweetFeature.State, Never>) {
		self.store = store
	}

	public var body: some View {
		_body
			.scaledFont(ofSize: 14)
			.background(color(\.background.primary))
	}

	@ViewBuilder
	private var _body: some View {
		HStack(alignment: .top) {
			VStack(spacing: 0) {
				makeAvatar(store.author.avatarURL)
				Rectangle()
					.fill(color(\.label.tertiary))
					.frame(width: 2)
					.frame(minHeight: 0)
					.padding(.trailing, 2)
					.padding(.vertical, 6)
			}
			VStack(alignment: .leading, spacing: 7) {
				makeHeader(
					displayName: store.author.displayName,
					username: store.author.username,
					creationDate: store.createdAt
				)
				makeContent(store.text)
				Text("Replying to @\(store.author.username)")
					.scaledFont(ofSize: 9)
					.foregroundStyle(color(\.label.secondary))
					.id("replying_to")
			}
		}
	}

	@ViewBuilder
	private func makeAvatar(
		_ avatarURL: URL?
	) -> some View {
		Circle()
			.stroke(color(\.label.secondary).opacity(0.3))
			.frame(width: 32, height: 32)
			.contentShape(Rectangle())
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
}
