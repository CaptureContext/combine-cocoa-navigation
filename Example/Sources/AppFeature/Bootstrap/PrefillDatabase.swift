import _Dependencies
import DatabaseSchema
import LocalExtensions

let defaultUsername = "capturecontext"
let defaultPassword = "psswrd"

func prefillDatabaseIfNeeded(autoSignIn: Bool) async throws {
	@Dependency(\.database)
	var database

	let modelContext = await database.context

	let currentUser = DatabaseSchema.UserModel(
		id: USID(),
		username: defaultUsername,
		password: .sha256(defaultPassword)!,
		displayName: "Capture Context"
	)

	let tweet = DatabaseSchema.TweetModel(
		id: USID(),
		author: currentUser,
		likes: [currentUser],
		content: "Hello, First World!"
	)

	let reply1 = DatabaseSchema.TweetModel(
		id: USID(),
		author: currentUser,
		replySource: tweet,
		content: "Hello, Second World!"
	)

	let reply2 = DatabaseSchema.TweetModel(
		id: USID(),
		author: currentUser,
		replySource: reply1,
		content: "Hello, Third World!"
	)

	modelContext.insert(reply2)

	try modelContext.save()

	guard autoSignIn else { return }

	@Dependency(\.apiClient)
	var apiClient

	try await apiClient.auth.signIn(
		username: defaultUsername,
		password: defaultPassword
	).get()
}
