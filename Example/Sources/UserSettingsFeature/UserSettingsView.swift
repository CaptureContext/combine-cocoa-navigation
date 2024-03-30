import _ComposableArchitecture
import SwiftUI
import AppUI

public struct UserSettingsView: ComposableView {
	private let store: StoreOf<UserSettingsFeature>

	@Environment(\.colorTheme)
	var colorTheme

	public init(_ store: StoreOf<UserSettingsFeature>) {
		self.store = store
	}

	public var body: some View {
		Text(store.id.usidString)
		Button("Logout") {
			store.send(.logout)
		}
		.tint(colorTheme(\.destructive))
		.bold()
	}
}

#Preview {
	UserSettingsView(Store(
		initialState: .init(id: .init()),
		reducer: UserSettingsFeature.init
	))
}
