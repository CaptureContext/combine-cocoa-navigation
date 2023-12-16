import ComposableArchitecture
import Foundation

public struct ProfileFeedFeature: Reducer {
	public init() {}

	public struct State: Equatable {
		public var items: IdentifiedArrayOf<TweetFeature.State>

		public init(
			items: IdentifiedArrayOf<TweetFeature.State> = []
		) {
			self.items = items
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case items(IdentifiedActionOf<TweetFeature>)
		case openProfile(UUID)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .items(.element(id, action: .tapOnAuthor)):
				return .send(.openProfile(id))

			default:
				return .none
			}
		}
		.forEach(
			\State.items,
			 action: \.items,
			 element: TweetFeature.init
		)
	}
}
