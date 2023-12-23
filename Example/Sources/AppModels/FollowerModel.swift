import LocalExtensions

public struct FollowerModel: Equatable, Identifiable {
	public var id: UUID { user.id }
	public var user: UserModel
	public var isFollowingYou: Bool
	public var isFollowedByYou: Bool

	public init(
		user: UserModel,
		isFollowingYou: Bool = false,
		isFollowedByYou: Bool = false
	) {
		self.user = user
		self.isFollowingYou = isFollowingYou
		self.isFollowedByYou = isFollowedByYou
	}
}

extension FollowerModel {
	public static func mock(
		user: UserModel = .mock(),
		isFollowingYou: Bool = false,
		isFollowedByYou: Bool = false
	) -> Self {
		.init(
			user: user,
			isFollowingYou: isFollowingYou,
			isFollowedByYou: isFollowedByYou
		)
	}
}
