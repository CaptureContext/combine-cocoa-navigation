import SwiftUI
import ComposableArchitecture

public struct UserSettingsView: View {
	let store: StoreOf<UserSettingsFeature>

	public init(_ store: StoreOf<UserSettingsFeature>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(store, observe: \.id) { viewStore in
			Text(viewStore.uuidString)
		}
	}
}

#Preview {
	UserSettingsView(Store(
		initialState: .init(id: .init()),
		reducer: UserSettingsFeature.init
	))
}
