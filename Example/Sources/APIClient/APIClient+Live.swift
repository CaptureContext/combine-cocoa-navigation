import _Dependencies
import SwiftData
import LocalExtensions
import DatabaseSchema
import AppModels

// Not sure if it's okay, just wanted to silence warnings
// this file is just mock implementation that uses local database
// for backend work simulation 😁
extension ModelContext: @unchecked Sendable {}

private let database = try! DatabaseSchema.createModelContext(.inMemory)

extension APIClient: DependencyKey {
	public func _accessDatabase(_ operation: (ModelContext) -> Void) {
		operation(database)
	}

	public static var liveValue: APIClient {
		@Box
		var currentUser: DatabaseSchema.UserModel?

		return .init(
			auth: .backendLike(
				database: database,
				currentUser: _currentUser
			),
			feed: .backendLike(
				database: database,
				currentUser: _currentUser
			),
			tweet: .backendLike(
				database: database,
				currentUser: _currentUser
			),
			user: .backendLike(
				database: database,
				currentUser: _currentUser
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
		var localizedDesctiption: String { "Unauthirized access" }
	}

	struct AuthenticationFailed: Swift.Error {
		var localizedDesctiption: String { "Username or password is incorrect" }
	}
}

extension APIClient.Auth {
	static func backendLike(
		database: ModelContext,
		currentUser: Box<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			signIn: .init { input in
				return Result {
					let pwHash = try Data.sha256(input.password).unwrap().get()

					let username = input.username
					guard let user = try database.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { model in
							model.username == username
							&& model.password == pwHash
						}
					).first 
					else { throw Errors.AuthenticationFailed() }

					currentUser.content = user
				}
			},
			signUp: .init { input in
				return Result {
					let username = input.username
					let userExists = try database.fetch(
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

					database.insert(user)
					try database.save()
					currentUser.content = user
				}
			},
			logout: .init { _ in
				currentUser.content = nil
			}
		)
	}
}

extension APIClient.Feed {
	static func backendLike(
		database: ModelContext,
		currentUser: Box<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			fetchTweets: .init { input in
				return Result {
					try database.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.replySource == nil }
					)
					.dropFirst(input.page * input.limit)
					.prefix(input.limit)
					.map { tweet in
						return TweetModel(
							id: tweet.id.usid(),
							authorID: tweet.author.id.usid(),
							replyTo: tweet.replySource?.id.usid(),
							repliesCount: tweet.replies.count,
							isLiked: currentUser.content.map { user in
								tweet.replies.contains { $0 === user }
							}.or(false),
							likesCount: tweet.likes.count,
							isReposted: currentUser.content.map(tweet.reposts.map(\.author).contains).or(false),
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
		database: ModelContext,
		currentUser: Box<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			like: .init { input in
				return Result {
					guard let user = currentUser.content
					else { throw Errors.UnauthenticatedRequest() }

					let shouldLike = input.value
					let isLiked = user.likedTweets.contains(where: { $0.id == input.id.rawValue })

					guard shouldLike != isLiked else { return }

					if shouldLike {
						let tweetID = input.id.rawValue
						guard let tweet = try database.fetch(
							DatabaseSchema.TweetModel.self,
							#Predicate { $0.id == tweetID }
						).first
						else { throw Errors.TweetDoesNotExist() }

						user.likedTweets.append(tweet)
					} else {
						user.likedTweets.removeAll { $0.id == input.id.rawValue }
					}

					try database.save()
				}
			},
			post: .init { input in
				return Result {
					guard let user = currentUser.content
					else { throw Errors.UnauthenticatedRequest() }

					database.insert(DatabaseSchema.TweetModel(
						id: USID(), 
						createdAt: .now,
						author: user,
						content: input
					))

					try database.save()
				}
			},
			repost: .init { input in
				return Result {
					guard let user = currentUser.content
					else { throw Errors.UnauthenticatedRequest() }

					let tweetID = input.id.rawValue
					guard let originalTweet = try database.fetch(
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

					try database.save()
				}
			},
			reply: .init { input in
				return Result {
					guard let user = currentUser.content
					else { throw Errors.UnauthenticatedRequest() }

					let tweetID = input.id.rawValue
					guard let originalTweet = try database.fetch(
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

					try database.save()
				}
			},
			delete: .init { input in
				return Result {
					guard let user = currentUser.content
					else { throw Errors.UnauthenticatedRequest() }

					guard let tweetToDelete = try database.fetch(
						DatabaseSchema.TweetModel.self,
						#Predicate { $0.id == input.rawValue }
					).first
					else { throw Errors.TweetDoesNotExist() }

					user.tweets.removeAll { $0 === tweetToDelete }

					try database.save()
				}
			},
			report: .init { input in
				// Pretend we did collect the report
				return .success(())
			},
			fetchReplies: .init { input in
				return Result {
					let tweetID = input.id.rawValue
					guard let tweet = try database.fetch(
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
								authorID: tweet.author.id.usid(),
								replyTo: tweet.replySource?.id.usid(),
								repliesCount: tweet.replies.count,
								isLiked: currentUser.content.map { user in
									tweet.replies.contains { $0 === user }
								}.or(false),
								likesCount: tweet.likes.count,
								isReposted: currentUser.content.map(tweet.reposts.map(\.author).contains).or(false),
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
		database: ModelContext,
		currentUser: Box<DatabaseSchema.UserModel?>
	) -> Self {
		.init(
			fetch: .init { id in
				return Result {
					guard let user = try database.fetch(
						DatabaseSchema.UserModel.self,
						#Predicate { $0.id == id.rawValue }
					).first
					else { throw Errors.UserDoesNotExist()}

					return UserModel(
						id: user.id.usid(),
						username: user.username,
						displayName: user.displayName,
						bio: user.bio,
						avatarURL: user.avatarURL
					)
				}
			},
			follow: .init { input in
				return Result {
					guard let user = currentUser.content
					else { throw Errors.UnauthenticatedRequest() }

					let shouldFollow = input.value
					let isFollowing = user.follows.contains(where: { $0.id == input.id.rawValue })

					guard shouldFollow != isFollowing else { return }

					if shouldFollow {
						let userID = input.id.rawValue
						guard let userToFollow = try database.fetch(
						 DatabaseSchema.UserModel.self,
						 #Predicate { $0.id == userID }
					 ).first
					 else { throw Errors.UserDoesNotExist() }

						user.follows.append(userToFollow)
					} else {
						user.follows.removeAll { $0.id == input.id.rawValue }
					}

					try database.save()
				}
			},
			report: .init { input in
				// Pretend we did collect the report
				return .success(())
			},
			fetchTweets: .init { input in
				return Result {
					let userID = input.id.rawValue
					guard let user = try database.fetch(
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
								authorID: tweet.author.id.usid(),
								replyTo: tweet.replySource?.id.usid(),
								repliesCount: tweet.replies.count,
								isLiked: currentUser.content.map { user in
									tweet.replies.contains { $0 === user }
								}.or(false),
								likesCount: tweet.likes.count,
								isReposted: currentUser.content.map(tweet.reposts.map(\.author).contains).or(false),
								repostsCount: tweet.reposts.count,
								text: tweet.content
							)
						}
				}
			}
		)
	}
}
