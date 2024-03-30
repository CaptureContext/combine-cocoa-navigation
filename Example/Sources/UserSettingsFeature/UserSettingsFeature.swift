import _ComposableArchitecture
import LocalExtensions
import AppModels

@Reducer
public struct UserSettingsFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable, Identifiable {
		public var id: USID

		public init(
			id: USID
		) {
			self.id = id
		}
	}

	@Dependency(\.currentUser)
	var currentUser

	@CasePathable
	public enum Action: Equatable {
		case logout
	}

	public var body: some ReducerOf<Self> {
		Pullback(\.logout) { state in
			currentUser.id = nil
			return .none
		}
	}
}
