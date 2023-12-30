import _ComposableArchitecture

extension AuthFeature {
	@Reducer
	public struct SignUp {
		@ObservableState
		public struct State: Equatable {
			public init() {}
		}

		@CasePathable
		public enum Action: Equatable {

		}

		public init() {}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}
}
