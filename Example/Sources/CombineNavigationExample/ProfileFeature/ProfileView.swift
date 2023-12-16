import SwiftUI
import ComposableArchitecture

public struct ProfileView: View {
	let store: StoreOf<ProfileFeature>

	public init(_ store: StoreOf<ProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		SwitchStore(store) { state in
			switch state {
			case .user:
				CaseLet(
					/ProfileFeature.State.user,
					action: ProfileFeature.Action.user,
					then: UserProfileView.init
				)
			case .currentUser:
				CaseLet(
					/ProfileFeature.State.currentUser,
					action: ProfileFeature.Action.currentUser,
					then: CurrentUserProfileView.init
				)
			}
		}
	}

	public struct IfLetView: View {
		let store: Store<
			ProfileFeature.State?,
			ProfileFeature.Action
		>

		public init(
		_ store: Store<
			ProfileFeature.State?,
			ProfileFeature.Action
		>) {
			self.store = store
		}

		public var body: some View {
			IfLetStore(store, then: ProfileView.init)
		}
	}
}

#Preview {
	NavigationStack {
		ProfileView(Store(
			initialState: .user(.init(
				model: .mock(),
				tweets: [
					.mock(),
					.mock(),
					.mock(),
					.mock(),
					.mock()
				]
			)),
			reducer: ProfileFeature.init
		))
	}
}
