import Foundation

extension APIClient {
	public struct Error: Swift.Error, Equatable {
		public let code: Code?
		public let message: String
		public let localizedDescription: String
		public let recoveryOptions: [RecoveryOption]

		internal init(
			code: Code?,
			message: String,
			localizedDescription: String? = nil,
			recoveryOptions: [RecoveryOption] = []
		) {
			self.code = code
			self.message = message
			self.localizedDescription = localizedDescription.or(message)
			self.recoveryOptions = recoveryOptions
		}

		public struct RecoveryOption: Equatable {
			var title: String
			var deeplink: String
		}
	}
}

extension APIClient.Error {
	public enum Code: Int, Equatable {
		case unauthenticated = 401
		case unauthorized = 403
		case notFound = 404
		case conflict = 409
	}
}

extension APIClient.Error {
	public init(_ error: Swift.Error) {
		if let _self = error as? Self {
			self = _self
		} else {
			self = .init(
				code: nil,
				message: "Something went wrong",
				localizedDescription: error.localizedDescription,
				recoveryOptions: []
			)
		}
	}
}

extension Swift.Error where Self == APIClient.Error {
	static var userAlreadyExists: APIClient.Error {
		.init(
			code: .conflict,
			message: """
				User already exists, \
				try recover your account or \
				use different credentials.
				"""
		)
	}

	static var usernameNotFound: APIClient.Error {
		.init(
			code: .notFound,
			message: """
				There is no such username in our \
				database, you probably forgot to sign up or \
				made some typo in your username.
				"""
		)
	}

	static var userNotFound: APIClient.Error {
		.init(
			code: .notFound,
			message: """
				The profile you are trying to view \
				probably was deleted 😢
				"""
		)
	}

	static var wrongPassword: APIClient.Error {
		.init(
			code: .unauthenticated,
			message: """
				The password was incorrect, try again \
				or create a new one using recovery options.
				""",
			recoveryOptions: [
				.init(
					title: "Reset password",
					deeplink: "/recovery/password-reset"
				)
			]
		)
	}

	static func unauthenticatedRequest(_ actionDescription: String) -> APIClient.Error {
		.init(
			code: .unauthenticated,
			message: """
			You need to be authenticated to \
			\(actionDescription).
			""",
			recoveryOptions: [
				.init(
					title: "Authenticate",
					deeplink: "/auth"
				)
			]
		)
	}

	static var tweetNotFound: APIClient.Error {
		.init(
			code: .notFound,
			message: """
				The tweet you are trying to view \
				probably was deleted 😢
				"""
		)
	}

	static var unauthorizedRequest: APIClient.Error {
		.init(
			code: .unauthorized,
			message: """
				You have no permission to perform this action 😢
				"""
		)
	}
}
