import ComposableArchitecture
import Foundation

public struct TweetsFeedFeature: Reducer {
	public init() {}

	public struct State: Equatable {
		public var list: TweetsListFeature.State

		@PresentationState
		public var detail: TweetDetailFeature.State?

		public init(
			list:  TweetsListFeature.State = [],
			detail: TweetDetailFeature.State? = nil
		) {
			self.list = list
			self.detail = detail
		}
	}

	@CasePathable
	public enum Action: Equatable {
		case list(TweetsListFeature.Action)
		case detail(PresentationAction<TweetDetailFeature.Action>)
		case openProfile(UUID)
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case
				let .list(.tweets(.element(_, .openProfile(id)))),
				let .detail(.presented(.openProfile(id))):
				return .send(.openProfile(id))
				
			case let .list(.tweets(.element(itemID, .openDetail))):
				state.detail = state.list[id: itemID].flatMap { tweet in
					.collectMock(for: tweet.id)
				}
				return .none
				
			default:
				return .none
			}
		}
		.ifLet(
			\State.$detail,
			 action: \.detail,
			 destination: TweetDetailFeature.init
		)

		Scope(
			state: \State.list,
			action: \.list,
			child: TweetsListFeature.init
		)
	}
}
