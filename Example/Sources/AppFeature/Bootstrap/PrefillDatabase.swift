import _Dependencies
import DatabaseSchema
import LocalExtensions

let defaultUsername = "capturecontext"
let defaultPassword = "psswrd"

func prefillDatabaseIfNeeded(autoSignIn: Bool) async throws {
	@Dependency(\.database)
	var database
	
	try await database.withContext { modelContext in
		
		let currentUser = DatabaseSchema.UserModel(
			id: USID(),
			username: defaultUsername,
			password: .sha256(defaultPassword)!,
			displayName: "Capture Context",
			bio: "We do cool stuff 😎🤘"
		)
		
		let otherUser1 = DatabaseSchema.UserModel(
			id: USID(),
			username: "johndoe",
			password: .sha256(defaultPassword)!,
			displayName: "John Doe"
		)
		
		let otherUser2 = DatabaseSchema.UserModel(
			id: USID(),
			username: "janedoe",
			password: .sha256(defaultPassword)!,
			displayName: "Jane Doe"
		)
		
		modelContext.insert(currentUser)
		modelContext.insert(otherUser1)
		modelContext.insert(otherUser2)
		
		var tweet = DatabaseSchema.TweetModel
			.init(
				id: .uuid(),
				content: "Hello, World!"
			)
			.insert(to: modelContext)
			.update(\.author, with: { $0 = otherUser1 })
			.update(\.likes, with: { $0.append(contentsOf: [currentUser]) })
		
		tweet = DatabaseSchema.TweetModel
			.init(
				id: .uuid(),
				content: "Hello, @\(otherUser1.username)!"
			)
			.insert(to: modelContext)
			.update(\.author, with: { $0 = currentUser })
			.update(\.replySource, with: { $0 = tweet })
			.update(\.likes, with: { $0.append(contentsOf: [otherUser1]) })
		
		
		tweet = DatabaseSchema.TweetModel
			.init(
				id: .uuid(),
				content: "Hello, First World!"
			)
			.insert(to: modelContext)
			.update(\.author, with: { $0 = currentUser })
			.update(\.likes, with: { $0.append(contentsOf: [otherUser1, otherUser2]) })
		
		
		tweet = DatabaseSchema.TweetModel
			.init(
				id: .uuid(),
				content: "Hello, Second World!"
			)
			.insert(to: modelContext)
			.update(\.author, with: { $0 = otherUser1 })
			.update(\.replySource, with: { $0 = tweet })
		
		
		tweet = DatabaseSchema.TweetModel
			.init(
				id: .uuid(),
				content: "Hello, Third World!"
			)
			.insert(to: modelContext)
			.update(\.author, with: { $0 = otherUser2 })
			.update(\.replySource, with: { $0 = tweet })
			.update(\.likes, with: { $0.append(contentsOf: [otherUser1, otherUser2]) })

		try modelContext.save()
	}
	
	guard autoSignIn else { return }
	
	@Dependency(\.apiClient)
	var apiClient
	
	try await apiClient.auth.signIn(
		username: defaultUsername,
		password: defaultPassword
	).get()
}

extension DatabaseSchema.TweetModel {
	static func makeTweet(
		with content: String
	) -> DatabaseSchema.TweetModel {
		DatabaseSchema.TweetModel(
			id: USID(),
			content: content
		)
	}
}
