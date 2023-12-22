import _ComposableArchitecture
import Foundation

@Reducer
public struct UserSettingsFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable, Identifiable {
		public var id: UUID

		public init(
			id: UUID
		) {
			self.id = id
		}
	}

	public enum Action: Equatable {}

	public var body: some ReducerOf<Self> {
		EmptyReducer()
	}
}
