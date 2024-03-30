import _ComposableArchitecture
import SwiftUI
import AppUI
import AppModels

public struct AuthView: ComposableView {
	private let store: StoreOf<AuthFeature>

	public init(_ store: StoreOf<AuthFeature>) {
		self.store = store
	}

	public var body: some View {
		switch store.state {
		case .signIn:
			SignInView?(store.scope(
				state: \.signIn,
				action: \.signIn
			))
		case .signUp:
			SignUpView?(store.scope(
				state: \.signUp,
				action: \.signUp
			))
		}
	}
}

extension AuthView {
	public struct SignInView: ComposableView {
		@Bindable
		private var store: StoreOf<AuthFeature.SignIn>

		@Environment(\.colorTheme)
		private var color

		public init(_ store: StoreOf<AuthFeature.SignIn>) {
			self.store = store
		}

		public var body: some View {
			VStack(spacing: 24) {
				VStack {
					TextField("Username", text: $store.username)
						.frame(height: 54)
						.padding(.horizontal)
						.background(
							RoundedRectangle(
								cornerRadius: 14,
								style: .continuous
							)
							.stroke(lineWidth: 1)
						)
					SecureField("Password", text: $store.password)
						.frame(height: 54)
						.padding(.horizontal)
						.background(
							RoundedRectangle(
								cornerRadius: 14,
								style: .continuous
							)
							.stroke(lineWidth: 1)
						)
				}
				.padding(.horizontal, 32)

				Button(action: {
					store.send(.signInButtonTapped)
				}) {
					Text("Sign In")
						.scaledFont(ofSize: 14, weight: .semibold)
						.frame(maxWidth: .infinity)
						.padding(.horizontal, 32)
						.frame(height: 54)
						.foregroundStyle(color(\.background))
						.background(
							RoundedRectangle(
								cornerRadius: 14,
								style: .continuous
							)
							.fill(color(\.label))
						)
				}
				.padding(.horizontal, 32)

				VStack {
					HStack {
						VStack { Divider() }
						Text("Do not have an account yet?")
							.layoutPriority(1)
						VStack { Divider() }
					}
					Button(action: {
						store.send(.signUpButtonTapped)
					}) {
						Text("Sign Up")
							.underline()
							.scaledFont(ofSize: 14, weight: .semibold)
							.foregroundStyle(color(\.accent))
					}
					.padding(.horizontal, 32)
				}
			}
		}
	}
}

extension AuthView {
	public struct SignUpView: ComposableView {
		@Bindable
		private var store: StoreOf<AuthFeature.SignUp>

		@Environment(\.colorTheme)
		private var color

		public init(_ store: StoreOf<AuthFeature.SignUp>) {
			self.store = store
		}

		public var body: some View {
			VStack(spacing: 24) {
				VStack {
					TextField("Username", text: $store.username)
						.frame(height: 54)
						.padding(.horizontal)
						.background(
							RoundedRectangle(
								cornerRadius: 14,
								style: .continuous
							)
							.stroke(lineWidth: 1)
						)
					SecureField("Password", text: $store.password)
						.frame(height: 54)
						.padding(.horizontal)
						.background(
							RoundedRectangle(
								cornerRadius: 14,
								style: .continuous
							)
							.stroke(lineWidth: 1)
						)
				}
				.padding(.horizontal, 32)

				Button(action: {
					store.send(.signUpButtonTapped)
				}) {
					Text("Sign Up")
						.scaledFont(ofSize: 14, weight: .semibold)
						.frame(maxWidth: .infinity)
						.padding(.horizontal, 32)
						.frame(height: 54)
						.foregroundStyle(color(\.background))
						.background(
							RoundedRectangle(
								cornerRadius: 14,
								style: .continuous
							)
							.fill(color(\.label))
						)
				}
				.padding(.horizontal, 32)

				VStack {
					HStack {
						VStack { Divider() }
						Text("Already have an account?")
							.layoutPriority(1)
						VStack { Divider() }
					}
					Button(action: {
						store.send(.signInButtonTapped)
					}) {
						Text("Sign In")
							.underline()
							.scaledFont(ofSize: 14, weight: .semibold)
							.foregroundStyle(color(\.accent))
					}
					.padding(.horizontal, 32)
				}
			}
		}
	}
}
