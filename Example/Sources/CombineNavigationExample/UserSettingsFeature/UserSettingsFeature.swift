import ComposableArchitecture
import Foundation

public struct UserSettingsFeature: Reducer {
	public init() {}

	public struct State: Equatable, Identifiable {
		public var id: UUID

		public init(
			id: UUID
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
