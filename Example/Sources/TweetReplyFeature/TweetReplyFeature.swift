import _ComposableArchitecture
import TweetFeature
import LocalExtensions

@Reducer
public struct TweetReplyFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		public var source: TweetFeature.State
		public var avatarURL: URL?
		public var replyText: String

		public init(
			source: TweetFeature.State,
			avatarURL: URL? = nil,
			replyText: String
		) {
			self.source = source
			self.avatarURL = avatarURL
			self.replyText = replyText
		}
	}

	@CasePathable
	public enum Action: Equatable, BindableAction {
		case binding(BindingAction<State>)
		case tweet
	}

	@Dependency(\.apiClient)
	var apiClient

	@Dependency(\.currentUser)
	var currentUser

	public var body: some ReducerOf<Self> {
		Pullback(\.tweet) { state in
			guard state.replyText.isNotEmpty else { return .none }
			let state = state
			return .run { send in
				#warning("Handle error")
				_ = await apiClient.tweet.reply(
					to: state.source.id,
					with: state.replyText
				)
			}
		}
		BindingReducer()
	}
}
