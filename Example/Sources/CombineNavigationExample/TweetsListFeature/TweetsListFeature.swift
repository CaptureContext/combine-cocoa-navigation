import ComposableArchitecture
import Foundation

public struct TweetsListFeature: Reducer {
	public init() {}

	public typealias State = IdentifiedArrayOf<TweetFeature.State>

	@CasePathable
	public enum Action: Equatable {
		case tweets(IdentifiedActionOf<TweetFeature>)
		case openDetail(for: UUID)
		case openProfile(UUID)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case let .tweets(.element(_, .openProfile(id))):
				return .send(.openProfile(id))

			case let .tweets(.element(_, .openDetail(id))):
				return .send(.openDetail(for: id))

			default:
				return .none
			}
		}
		.forEach(
			\State.self,
			 action: \.tweets,
			 element: TweetFeature.init
		)
	}
}
