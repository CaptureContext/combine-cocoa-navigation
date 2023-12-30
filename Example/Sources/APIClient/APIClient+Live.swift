import _Dependencies
import SwiftData
import LocalExtensions
import DatabaseSchema
import AppModels

extension APIClient: DependencyKey {
	public static var liveValue: APIClient {
		@Reference
		var currentUser: DatabaseSchema.UserModel?

		@Dependency(\.currentUser)
		var userIDContainer

		let trackedCurrentUser = _currentUser.onSet { user in
			userIDContainer.id = user?.id.usid()
		}

		return .init(
			auth: .backendLike(
				currentUser: trackedCurrentUser
			),
			feed: .backendLike(
				currentUser: trackedCurrentUser
			),
			tweet: .backendLike(
				currentUser: trackedCurrentUser
			),
			user: .backendLike(
				currentUser: trackedCurrentUser
			)
		)
	}
}

extension APIClient.Auth {
	static func backendLike(
		currentUser: Reference<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			signIn: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					let pwHash = try Data.sha256(input.password).unwrap().get()

					let username = input.username
					guard let user = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.username == username }
					).first
					else { throw .usernameNotFound }

					guard user.password == pwHash else {
						throw .wrongPassword
					}

					currentUser.wrappedValue = user
				}.mapError(APIClient.Error.init)
			},
			signUp: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					let username = input.username
					let userExists = try await database.context.fetch(
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

					await database.context.insert(user)
					try await database.context.save()
					currentUser.wrappedValue = user
				}.mapError(APIClient.Error.init)
			},
			logout: .init { _ in
				currentUser.wrappedValue = nil
			}
		)
	}
}

extension APIClient.Feed {
	static func backendLike(
		currentUser: Reference<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			fetchTweets: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					return try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.replySource == nil }
					)
					.dropFirst(input.page * input.limit)
					.prefix(input.limit)
					.map { tweet in
						return TweetModel(
							id: tweet.id.usid(),
							author: .init(
								id: tweet.author.id.usid(),
								avatarURL: tweet.author.avatarURL,
								displayName: tweet.author.displayName,
								username: tweet.author.username
							),
							createdAt: tweet.createdAt,
							replyTo: tweet.replySource?.id.usid(),
							repliesCount: tweet.replies.count,
							isLiked: currentUser.wrappedValue.map { user in
								tweet.likes.contains { $0.id == user.id }
							}.or(false),
							likesCount: tweet.likes.count,
							isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
							repostsCount: tweet.reposts.count,
							text: tweet.content
						)
					}
				}.mapError(APIClient.Error.init)
			}
		)
	}
}

extension APIClient.Tweet {
	static func backendLike(
		currentUser: Reference<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			fetch: .init { input in
				return await Result {
					@Dependency(\.database)
					var database
					let tweetID = input.rawValue
					guard let tweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw .tweetNotFound }

					return TweetModel(
						id: tweet.id.usid(),
						author: .init(
							id: tweet.author.id.usid(),
							avatarURL: tweet.author.avatarURL,
							displayName: tweet.author.displayName,
							username: tweet.author.username
						),
						createdAt: tweet.createdAt,
						replyTo: tweet.replySource?.id.usid(),
						repliesCount: tweet.replies.count,
						isLiked: currentUser.wrappedValue.map { user in
							tweet.likes.contains { $0 === user }
						}.or(false),
						likesCount: tweet.likes.count,
						isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
						repostsCount: tweet.reposts.count,
						text: tweet.content
					)
				}.mapError(APIClient.Error.init)
			},
			like: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = currentUser.wrappedValue
					else { throw .unauthenticatedRequest("like a tweet") }

					let shouldLike = input.value
					let isLiked = user.likedTweets.contains(where: { $0.id == input.id.rawValue })

					guard shouldLike != isLiked else { return }

					if shouldLike {
						let tweetID = input.id.rawValue
						guard let tweet = try await database.context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw .tweetNotFound }

						user.likedTweets.append(tweet)
					} else {
						user.likedTweets.removeAll { $0.id == input.id.rawValue }
					}

					try await database.context.save()
				}.mapError(APIClient.Error.init)
			},
			post: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = currentUser.wrappedValue
					else { throw .unauthenticatedRequest("post a tweet") }

					await database.context.insert(DatabaseSchema.TweetModel(
						id: USID(),
						createdAt: .now,
						author: user,
						content: input
					))

					try await database.context.save()
				}.mapError(APIClient.Error.init)
			},
			repost: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = currentUser.wrappedValue
					else { throw .unauthenticatedRequest("repost a tweet") }

					let tweetID = input.id.rawValue
					guard let originalTweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw .tweetNotFound }

					originalTweet.reposts.append(DatabaseSchema.TweetModel(
						id: USID(),
						createdAt: .now,
						author: user,
						content: input.content
					))

					try await database.context.save()
				}.mapError(APIClient.Error.init)
			},
			reply: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = currentUser.wrappedValue
					else { throw .unauthenticatedRequest("reply to a tweet") }

					let tweetID = input.id.rawValue
					guard let originalTweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw .tweetNotFound }

					originalTweet.replies.append(DatabaseSchema.TweetModel(
						id: USID(),
						createdAt: .now,
						author: user,
						content: input.content
					))

					try await database.context.save()
				}.mapError(APIClient.Error.init)
			},
			delete: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = currentUser.wrappedValue
					else { throw .unauthenticatedRequest("delete tweets") }

					guard let tweetToDelete = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == input.rawValue }
					).first
					else { throw .tweetNotFound }

					user.tweets.removeAll { $0 === tweetToDelete }

					try await database.context.save()
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

					let tweetID = input.id.rawValue
					guard let tweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw .tweetNotFound }

					return tweet.replies
						.dropFirst(input.page * input.limit)
						.prefix(input.limit)
						.map { tweet in
							return TweetModel(
								id: tweet.id.usid(),
								author: .init(
									id: tweet.author.id.usid(),
									avatarURL: tweet.author.avatarURL,
									displayName: tweet.author.displayName,
									username: tweet.author.username
								),
								createdAt: tweet.createdAt,
								replyTo: tweet.replySource?.id.usid(),
								repliesCount: tweet.replies.count,
								isLiked: currentUser.wrappedValue.map { user in
									tweet.likes.contains { $0.id == user.id }
								}.or(false),
								likesCount: tweet.likes.count,
								isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
								repostsCount: tweet.reposts.count,
								text: tweet.content
							)
						}
				}.mapError(APIClient.Error.init)
			}
		)
	}
}

extension APIClient.User {
	static func backendLike(
		currentUser: Reference<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			fetch: .init { id in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.id == id.rawValue }
					).first
					else { throw .userNotFound }

					return UserInfoModel(
						id: user.id.usid(),
						username: user.username,
						displayName: user.displayName,
						bio: user.bio,
						avatarURL: user.avatarURL,
						isFollowingYou: currentUser.wrappedValue?.followers.contains { $0 === user } ?? false,
						isFollowedByYou: user.followers.contains { $0 === currentUser.wrappedValue },
						followsCount: user.follows.count,
						followersCount: user.followers.count
					)
				}.mapError(APIClient.Error.init)
			},
			follow: .init { input in
				return await Result {
					@Dependency(\.database)
					var database

					guard let user = currentUser.wrappedValue
					else { throw .unauthenticatedRequest("follow or unfollow profiles") }

					let shouldFollow = input.value
					let isFollowing = user.follows.contains(where: { $0.id == input.id.rawValue })

					guard shouldFollow != isFollowing else { return }

					if shouldFollow {
						let userID = input.id.rawValue
						guard let userToFollow = try await database.context.fetch(
							DatabaseSchema.UserModel.self,
							#Predicate { $0.id == userID }
						).first
						else { throw .userNotFound }

						user.follows.append(userToFollow)
					} else {
						user.follows.removeAll { $0.id == input.id.rawValue }
					}

					try await database.context.save()
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
					let userID = input.id.rawValue
					guard let user = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.id == userID }
					).first
					else { throw .userNotFound }

					return user.tweets
						.dropFirst(input.page * input.limit)
						.prefix(input.limit)
						.map { tweet in
							return TweetModel(
								id: tweet.id.usid(),
								author:.init(
									id: tweet.author.id.usid(),
									avatarURL: tweet.author.avatarURL,
									displayName: tweet.author.displayName,
									username: tweet.author.username
								),
								createdAt: tweet.createdAt,
								replyTo: tweet.replySource?.id.usid(),
								repliesCount: tweet.replies.count,
								isLiked: currentUser.wrappedValue.map { user in
									tweet.likes.contains { $0 === user }
								}.or(false),
								likesCount: tweet.likes.count,
								isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
								repostsCount: tweet.reposts.count,
								text: tweet.content
							)
						}
				}.mapError(APIClient.Error.init)
			}
		)
	}
}
