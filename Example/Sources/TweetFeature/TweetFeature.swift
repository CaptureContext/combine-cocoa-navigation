import _ComposableArchitecture
import LocalExtensions
import AppModels

@Reducer
public struct TweetFeature {
	public init() {}

	@ObservableState
	public struct State: Equatable, Identifiable {
		public var id: USID
		public var replyTo: USID?
		public var repliesCount: Int
		public var isLiked: Bool
		public var likesCount: Int
		public var isReposted: Bool
		public var repostsCount: Int
		public var author: UserModel
		public var text: String

		public init(
			id: USID,
			replyTo: USID? = nil,
			repliesCount: Int = 0,
			isLiked: Bool = false,
			likesCount: Int = 0,
			isReposted: Bool = false,
			repostsCount: Int = 0,
			author: UserModel,
			text: String
		) {
			self.id = id
			self.replyTo = replyTo
			self.repliesCount = repliesCount
			self.isLiked = isLiked
			self.likesCount = likesCount
			self.isReposted = isReposted
			self.repostsCount = repostsCount
			self.author = author
			self.text = text
		}

		public static func mock(
		 model: TweetModel
	 ) -> Self {
		 .mock(
			 id: model.id,
			 replyTo: model.replyTo,
			 author: .mock(id: model.authorID),
			 text: model.text
		 )
	 }

	 public static func mock(
		 id: USID = .init(),
		 replyTo: USID? = nil,
		 author: UserModel = .mock(),
		 text: String = """
		 Nisi commodo non ea consequat qui ad pariatur dolore elit ipsum laboris ipsum. \
		 Culpa anim incididunt sunt minim ut eiusmod nulla mollit minim qui. \
		 In ad laboris labore irure ea ea officia.
		 """
		) -> Self {
		 .init(
			 id: id,
			 replyTo: replyTo,
			 author: author,
			 text: text
		 )
	 }

	 public func mockReply(
		 id: USID = .init(),
		 author: UserModel = .mock(),
		 text: String = """
		 Nisi commodo non ea consequat qui ad pariatur dolore elit ipsum laboris ipsum. \
		 Culpa anim incididunt sunt minim ut eiusmod nulla mollit minim qui. \
		 In ad laboris labore irure ea ea officia.
		 """
		) -> Self {
		 .init(
			 id: id,
			 replyTo: self.id,
			 author: author,
			 text: text
		 )
	 }
	}

	public enum Action: Equatable {
		case tap
		case tapOnAuthor
		case openDetail(for: USID)
		case openProfile(USID)
	}

	public func reduce(
		into state: inout State,
		action: Action
	) -> Effect<Action> {
		switch action {
		case .tap:
			return .send(.openDetail(for: state.id))

		case .tapOnAuthor:
			return.send(.openProfile(state.author.id))

		default:
			return .none
		}
	}
}
