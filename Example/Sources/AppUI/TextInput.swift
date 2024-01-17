import SwiftUI
import LocalExtensions

public enum TextInput {
	public struct State: Equatable {
		public var title: LocalizedStringKey
		public var text: String
		public var prompt: String?
	}

	public struct View: SwiftUI.View {
		@Binding
		private var state: State

		public init(_ state: Binding<State>) {
			self._state = state
		}

		public var body: some SwiftUI.View {
			TextField(
				state.title,
				text: $state.text,
				prompt: state.prompt.map { Text($0) }
			)
		}
	}
}

#Preview {
	TextInput.View(.variable(.init(title: "title", text: "text", prompt: "prompt")))
}
