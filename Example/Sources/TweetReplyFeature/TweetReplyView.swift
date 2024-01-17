import _ComposableArchitecture
import SwiftUI
import TweetFeature

public struct TweetReplyView: ComposableView {
	private let store: StoreOf<TweetReplyFeature>

	@Environment(\.colorTheme)
	private var color

	@FocusState
	private var focused: Bool

	public init(_ store: StoreOf<TweetReplyFeature>) {
		self.store = store
	}

	public var body: some View {
		_body
	}

	private var _body: some View {
		ScrollView(.vertical) {
			 VStack(spacing: 0) {
				 makeTweetPreview()
				 makeTweetInputField()
				 Spacer(minLength: 8)
			 }
			 .padding(.horizontal)
		 }
		.toolbar {
			Button("Tweet") {
				store.send(.tweet)
			}
			.disabled(store.replyText.isEmpty)
		}
		.toolbarRole(.navigationStack)
		.onAppear { focused = true }
	}

	@ViewBuilder
	private func makeTweetPreview() -> some View {
		SimpleTweetPreviewView(store.scope(
			state: \.source,
			action: \.never
		))
	}

	@ViewBuilder
	private func makeTweetInputField() -> some View {
		HStack(alignment: .top) {
			makeAvatar(nil)
			TextEditor(text: Binding(
				get: { store.replyText },
				set: { store.send(.binding(.set(\.replyText, $0))) })
			)
			.focused($focused)
			.textEditorStyle(PlainTextEditorStyle())
			.scrollDisabled(true)
			Button(action: { store.send(.tweet) }) {
				Image(systemName: "paperplane.fill")
			}
			.frame(width: 32, height: 32)
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
}
