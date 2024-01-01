import Dependencies
import SwiftData
import LocalExtensions
import DatabaseSchema
import AppModels

extension APIClient: DependencyKey {
	public static var liveValue: APIClient {

		return .init(
			auth: .backendLike(),
			feed: .backendLike(),
			tweet: .backendLike(),
			user: .backendLike()
		)
	}
}

extension ModelContext {
	fileprivate var currentUser: DatabaseSchema.UserModel? {
		@Dependency(\.currentUser)
		var userIDContainer

		guard let currentUserID = userIDContainer.id?.rawValue
		else { return nil }

		return try? fetch(
			DatabaseSchema.UserModel.self,
			#Predicate { $0.id == currentUserID }
		).first
	}
}

extension DatabaseSchema.TweetModel {
	public func toAPIModel() -> AppModels.TweetModel {
		@Dependency(\.currentUser)
		var currentUser

		return TweetModel(
			id: id.usid(),
			author: .init(
				id: author!.id.usid(),
				avatarURL: author!.avatarURL,
				displayName: author!.displayName,
				username: author!.username
			),
			createdAt: createdAt,
			replyTo: replySource?.id.usid(),
			repliesCount: replies.count,
			isLiked: currentUser.id.map { userID in
				likes.contains { (like: DatabaseSchema.UserModel) in
					like.id == userID.rawValue
				}
			}.or(false),
			likesCount: likes.count,
			isReposted: currentUser.id.map { userID in
				reposts.contains { (repost: DatabaseSchema.TweetModel) in
					repost.author!.id == userID.rawValue
				}
			}.or(false),
			repostsCount: reposts.count,
			text: content
		)
	}
}

extension APIClient.Auth {
	static func backendLike() -> Self {
		.init(
			signIn: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					@Dependency(\.currentUser)
					var currentUser

					try await database.withContext { context in
						let pwHash = try Data.sha256(input.password).unwrap().get()

						let username = input.username
						guard let user = try context.fetch(
							DatabaseSchema.UserModel.self,
							#Predicate { $0.username == username }
						).first
						else { throw .usernameNotFound }

						guard user.password == pwHash else {
							throw .wrongPassword
						}

						currentUser.id = user.id.usid()
					}
				}.mapError(APIClient.Error.init)
			},
			signUp: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					@Dependency(\.currentUser)
					var currentUser

					try await database.withContext { context in
						let username = input.username
						let userExists = try context.fetch(
							DatabaseSchema.UserModel.self,
							#Predicate { $0.username == username }
						).isNotEmpty

						guard !userExists
						else { throw .userAlreadyExists }

						let pwHash = try Data.sha256(input.password).unwrap().get()

						let user = DatabaseSchema.UserModel(
							id: USID(),
							username: input.username,
							password: pwHash
						)

						context.insert(user)
						try context.save()
						currentUser.id = user.id.usid()
					}
				}.mapError(APIClient.Error.init)
			},
			logout: .init { _ in
				@Dependency(\.currentUser)
				var currentUser

				currentUser.id = nil
			}
		)
	}
}

extension APIClient.Feed {
	static func backendLike() -> APIClient.Feed {
		return .init(
			fetchTweets: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					return try await database.withContext { context in
						return try context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.replySource == nil }
						)
						.dropFirst(input.page * input.limit)
						.prefix(input.limit)
						.map { $0.toAPIModel() }
					}
				}.mapError(APIClient.Error.init)
			}
		)
	}
}

extension APIClient.Tweet {
	static func backendLike() -> Self {
		.init(
			fetch: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					return try await database.withContext { context in
						let tweetID = input.rawValue

						guard let tweet = try context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw .tweetNotFound }

						return tweet.toAPIModel()
					}
				}.mapError(APIClient.Error.init)
			},
			like: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					try await database.withContext { context in
						guard let user = context.currentUser
						else { throw .unauthenticatedRequest("like a tweet") }

						let shouldLike = input.value
						let tweetID = input.id.rawValue
						let isLiked = user.likedTweets.contains(where: { $0.id == tweetID })

						guard shouldLike != isLiked else { return }

						if shouldLike {
							guard let tweet = try context.fetch(
								DatabaseSchema.TweetModel.self,
								#Predicate { $0.id == tweetID }
							).first
							else { throw .tweetNotFound }

							user.likedTweets.append(tweet)
						} else {
							user.likedTweets.removeAll { $0.id == tweetID }
						}

						try context.save()
					}
				}.mapError(APIClient.Error.init)
			},
			post: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					try await database.withContext { context in
						guard let user = context.currentUser
						else { throw .unauthenticatedRequest("post a tweet") }

						DatabaseSchema.TweetModel(
							id: USID(),
							createdAt: .now,
							content: input
						)
						.insert(to: context)
						.update(\.author, with: { $0 = user })

						try context.save()
					}
				}.mapError(APIClient.Error.init)
			},
			repost: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					try await database.withContext { context in
						guard let user = context.currentUser
						else { throw .unauthenticatedRequest("repost a tweet") }

						let tweetID = input.id.rawValue
						guard let originalTweet = try context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw .tweetNotFound }

						DatabaseSchema.TweetModel(
							id: USID(),
							createdAt: .now,
							content: input.content
						)
						.insert(to: context)
						.update(\.author, with: { $0 = user })
						.update(\.repostSource, with: { $0 = originalTweet })

						try context.save()
					}
				}.mapError(APIClient.Error.init)
			},
			reply: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					try await database.withContext { context in
						guard let user = context.currentUser
						else { throw .unauthenticatedRequest("reply to a tweet") }

						let tweetID = input.id.rawValue
						guard let originalTweet = try context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw .tweetNotFound }

						DatabaseSchema.TweetModel(
							id: USID(),
							createdAt: .now,
							content: input.content
						)
						.insert(to: context)
						.update(\.author, with: { $0 = user })
						.update(\.replySource, with: { $0 = originalTweet })

						try context.save()
					}
				}.mapError(APIClient.Error.init)
			},
			delete: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					try await database.withContext { context in
						guard let user = context.currentUser
						else { throw .unauthenticatedRequest("delete tweets") }

						let tweetID = input.rawValue
						guard let tweetToDelete = try context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw .tweetNotFound }

						user.tweets.removeAll { $0.id == tweetToDelete.id }

						try context.save()
					}
				}.mapError(APIClient.Error.init)
			},
			report: .init { input in
				// Pretend we did collect the report
				return .success(())
			},
			fetchReplies: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					return try await database.withContext { context in
						let tweetID = input.id.rawValue
						guard let tweet = try context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw .tweetNotFound }

						return tweet.replies
							.dropFirst(input.page * input.limit)
							.prefix(input.limit)
							.map { $0.toAPIModel() }
					}
				}.mapError(APIClient.Error.init)
			}
		)
	}
}

extension APIClient.User {
	static func backendLike() -> Self {
		.init(
			fetch: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					return try await database.withContext { context in
						let currentUser = context.currentUser
						let userID = input.rawValue
						guard let user = try context.fetch(
							DatabaseSchema.UserModel.self,
							#Predicate { $0.id == userID }
						).first
						else { throw .userNotFound }

						return UserInfoModel(
							id: user.id.usid(),
							username: user.username,
							displayName: user.displayName,
							bio: user.bio,
							avatarURL: user.avatarURL,
							isFollowingYou: currentUser.map { currentUser in
								currentUser.followers.contains { $0.id == user.id }
							}.or(false),
							isFollowedByYou: currentUser.map { currentUser in
								user.followers.contains { $0.id == currentUser.id }
							}.or(false),
							followsCount: user.follows.count,
							followersCount: user.followers.count
						)
					}
				}.mapError(APIClient.Error.init)
			},
			follow: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					try await database.withContext { context in
						guard let user = context.currentUser
						else { throw .unauthenticatedRequest("follow or unfollow profiles") }

						let userID = input.id.rawValue
						let shouldFollow = input.value
						let isFollowing = user.follows.contains(where: { $0.id == userID })

						guard shouldFollow != isFollowing else { return }

						if shouldFollow {
							guard let userToFollow = try context.fetch(
								DatabaseSchema.UserModel.self,
								#Predicate { $0.id == userID }
							).first
							else { throw .userNotFound }

							user.follows.append(userToFollow)
						} else {
							user.follows.removeAll { $0.id == userID }
						}

						try context.save()
					}

				}.mapError(APIClient.Error.init)
			},
			report: .init { input in
				// Pretend we did collect the report
				return .success(())
			},
			fetchTweets: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					return try await database.withContext { context in
						let userID = input.id.rawValue
						guard let user = try context.fetch(
							DatabaseSchema.UserModel.self,
							#Predicate { $0.id == userID }
						).first
						else { throw .userNotFound }

						return user.tweets
							.dropFirst(input.page * input.limit)
							.prefix(input.limit)
							.map { $0.toAPIModel() }
					}
				}.mapError(APIClient.Error.init)
			}
		)
	}
}
