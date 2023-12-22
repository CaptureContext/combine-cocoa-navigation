import _ComposableArchitecture
import SwiftUI

public struct UserSettingsView: ComposableView {
	let store: StoreOf<UserSettingsFeature>

	public init(_ store: StoreOf<UserSettingsFeature>) {
		self.store = store
	}

	public var body: some View {
		Text(store.id.uuidString)
	}
}

#Preview {
	UserSettingsView(Store(
		initialState: .init(id: .init()),
		reducer: UserSettingsFeature.init
	))
}
