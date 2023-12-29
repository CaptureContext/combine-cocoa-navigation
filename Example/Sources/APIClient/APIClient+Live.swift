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

private enum Errors {
	struct UserExists: Swift.Error {
		var localizedDesctiption: String { "User exists" }
	}

	struct UserDoesNotExist: Swift.Error {
		var localizedDesctiption: String { "User doesn't exist" }
	}

	struct UnauthenticatedRequest: Swift.Error {
		var localizedDesctiption: String { "Request requires authentication" }
	}

	struct TweetDoesNotExist: Swift.Error {
		var localizedDesctiption: String { "Tweet doesn't exist" }
	}
	
	struct UnauthorizedRequest: Swift.Error {
		var localizedDesctiption: String { "Unauthorized access" }
	}

	struct AuthenticationFailed: Swift.Error {
		var localizedDesctiption: String { "Username or password is incorrect" }
	}
}

extension APIClient.Auth {
	static func backendLike(
		currentUser: Reference<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			signIn: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					let pwHash = try Data.sha256(input.password).unwrap().get()

					let username = input.username
					guard let user = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { model in
							model.username == username
							&& model.password == pwHash
						}
					).first 
					else { throw Errors.AuthenticationFailed() }

					currentUser.wrappedValue = user
				}
			},
			signUp: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					let username = input.username
					let userExists = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.username == username }
					).isNotEmpty

					guard !userExists 
					else { throw Errors.UserExists() }

					let pwHash = try Data.sha256(input.password).unwrap().get()

					let user = DatabaseSchema.UserModel(
						id: USID(),
						username: input.username,
						password: pwHash
					)

					await database.context.insert(user)
					try await database.context.save()
					currentUser.wrappedValue = user
				}
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
				@Dependency(\.database)
				var database

				return await Result { 
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
								username: tweet.author.username
							),
							replyTo: tweet.replySource?.id.usid(),
							repliesCount: tweet.replies.count,
							isLiked: currentUser.wrappedValue.map { user in
								tweet.replies.contains { $0 === user }
							}.or(false),
							likesCount: tweet.likes.count,
							isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
							repostsCount: tweet.reposts.count,
							text: tweet.content
						)
					}
				}
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
				@Dependency(\.database)
				var database

				return await Result { 
					let tweetID = input.rawValue
					guard let tweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw Errors.TweetDoesNotExist() }

					return TweetModel(
						id: tweet.id.usid(),
						author: .init(
							id: tweet.author.id.usid(),
							username: tweet.author.username
						),
						replyTo: tweet.replySource?.id.usid(),
						repliesCount: tweet.replies.count,
						isLiked: currentUser.wrappedValue.map { user in
							tweet.replies.contains { $0 === user }
						}.or(false),
						likesCount: tweet.likes.count,
						isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
						repostsCount: tweet.reposts.count,
						text: tweet.content
					)
				}
			},
			like: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = currentUser.wrappedValue
					else { throw Errors.UnauthenticatedRequest() }

					let shouldLike = input.value
					let isLiked = user.likedTweets.contains(where: { $0.id == input.id.rawValue })

					guard shouldLike != isLiked else { return }

					if shouldLike {
						let tweetID = input.id.rawValue
						guard let tweet = try await database.context.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw Errors.TweetDoesNotExist() }

						user.likedTweets.append(tweet)
					} else {
						user.likedTweets.removeAll { $0.id == input.id.rawValue }
					}

					try await database.context.save()
				}
			},
			post: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = currentUser.wrappedValue
					else { throw Errors.UnauthenticatedRequest() }

					await database.context.insert(DatabaseSchema.TweetModel(
						id: USID(), 
						createdAt: .now,
						author: user,
						content: input
					))

					try await database.context.save()
				}
			},
			repost: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = currentUser.wrappedValue
					else { throw Errors.UnauthenticatedRequest() }

					let tweetID = input.id.rawValue
					guard let originalTweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw Errors.TweetDoesNotExist() }

					originalTweet.reposts.append(DatabaseSchema.TweetModel(
						id: USID(),
						createdAt: .now,
						author: user,
						content: input.content
					))

					try await database.context.save()
				}
			},
			reply: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = currentUser.wrappedValue
					else { throw Errors.UnauthenticatedRequest() }

					let tweetID = input.id.rawValue
					guard let originalTweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw Errors.TweetDoesNotExist() }

					originalTweet.replies.append(DatabaseSchema.TweetModel(
						id: USID(),
						createdAt: .now,
						author: user,
						content: input.content
					))

					try await database.context.save()
				}
			},
			delete: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = currentUser.wrappedValue
					else { throw Errors.UnauthenticatedRequest() }

					guard let tweetToDelete = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == input.rawValue }
					).first
					else { throw Errors.TweetDoesNotExist() }

					user.tweets.removeAll { $0 === tweetToDelete }

					try await database.context.save()
				}
			},
			report: .init { input in
				// Pretend we did collect the report
				return .success(())
			},
			fetchReplies: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					let tweetID = input.id.rawValue
					guard let tweet = try await database.context.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == tweetID }
					).first
					else { throw Errors.TweetDoesNotExist() }

					return tweet.replies
						.dropFirst(input.page * input.limit)
						.prefix(input.limit)
						.map { tweet in
							return TweetModel(
								id: tweet.id.usid(),
								author: .init(
								 id: tweet.author.id.usid(),
								 username: tweet.author.username
							 ),
								replyTo: tweet.replySource?.id.usid(),
								repliesCount: tweet.replies.count,
								isLiked: currentUser.wrappedValue.map { user in
									tweet.replies.contains { $0 === user }
								}.or(false),
								likesCount: tweet.likes.count,
								isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
								repostsCount: tweet.reposts.count,
								text: tweet.content
							)
						}
				}
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
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.id == id.rawValue }
					).first
					else { throw Errors.UserDoesNotExist()}

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
				}
			},
			follow: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					guard let user = currentUser.wrappedValue
					else { throw Errors.UnauthenticatedRequest() }

					let shouldFollow = input.value
					let isFollowing = user.follows.contains(where: { $0.id == input.id.rawValue })

					guard shouldFollow != isFollowing else { return }

					if shouldFollow {
						let userID = input.id.rawValue
						guard let userToFollow = try await database.context.fetch(
						 DatabaseSchema.UserModel.self,
						 #Predicate { $0.id == userID }
					 ).first
					 else { throw Errors.UserDoesNotExist() }

						user.follows.append(userToFollow)
					} else {
						user.follows.removeAll { $0.id == input.id.rawValue }
					}

					try await database.context.save()
				}
			},
			report: .init { input in
				// Pretend we did collect the report
				return .success(())
			},
			fetchTweets: .init { input in
				@Dependency(\.database)
				var database

				return await Result { 
					let userID = input.id.rawValue
					guard let user = try await database.context.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.id == userID }
					).first
					else { throw Errors.UserDoesNotExist() }

					return user.tweets
						.dropFirst(input.page * input.limit)
						.prefix(input.limit)
						.map { tweet in
							return TweetModel(
								id: tweet.id.usid(),
								author: .init(
								 id: tweet.author.id.usid(),
								 username: tweet.author.username
							 ),
								replyTo: tweet.replySource?.id.usid(),
								repliesCount: tweet.replies.count,
								isLiked: currentUser.wrappedValue.map { user in
									tweet.replies.contains { $0 === user }
								}.or(false),
								likesCount: tweet.likes.count,
								isReposted: currentUser.wrappedValue.map(tweet.reposts.map(\.author).contains).or(false),
								repostsCount: tweet.reposts.count,
								text: tweet.content
							)
						}
				}
			}
		)
	}
}
