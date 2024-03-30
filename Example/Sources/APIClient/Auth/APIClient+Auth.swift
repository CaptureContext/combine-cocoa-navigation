import LocalExtensions
import AppModels

extension APIClient {
	public struct Auth: ClientOperationsGroup {
		public init(
			signIn: Operations.SignIn,
			signUp: Operations.SignUp,
			logout: Operations.Logout
		) {
			self.signIn = signIn
			self.signUp = signUp
			self.logout = logout
		}

		public var signIn: Operations.SignIn
		public var signUp: Operations.SignUp
		public var logout: Operations.Logout
	}
}

extension APIClient.Auth {
	public enum Operations {}
}

extension APIClient.Auth.Operations {
	public struct SignIn: ClientOperation {
		public typealias Input = (
			username: String,
			password: String
		)

		public typealias Output = Result<Void, APIClient.Error>

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			username: String,
			password: String
		) async -> Output {
			await asyncCall((username, password))
		}
	}

	public struct SignUp: ClientOperation {
		public typealias Input = (
			username: String,
			password: String
		)

		public typealias Output = Result<Void, APIClient.Error>

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			username: String,
			password: String
		) async -> Output {
			await asyncCall((username, password))
		}
	}

	public struct Logout: ClientOperation {
		public typealias Input = Void

		public typealias Output = Void

		public var asyncCall: AsyncSignature

		public init(_ asyncCall: @escaping AsyncSignature) {
			self.asyncCall = asyncCall
		}

		public func callAsFunction(
			username: String,
			password: String
		) async -> Output {
			await asyncCall(())
		}
	}
}
