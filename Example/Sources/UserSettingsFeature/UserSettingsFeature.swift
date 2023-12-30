import _ComposableArchitecture
import LocalExtensions

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

	@CasePathable
	public enum Action: Equatable {}

	public var body: some ReducerOf<Self> {
		EmptyReducer()
	}
}
