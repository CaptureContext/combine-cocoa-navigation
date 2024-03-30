import _ComposableArchitecture
import SwiftUI
import AppModels
import ExternalUserProfileFeature
import CurrentUserProfileFeature
import CocoaExtensions
import CocoaAliases

public struct UserProfileView: ComposableView {
	public typealias State = UserProfileFeature.State
	public typealias Action = UserProfileFeature.Action

	private let store: StoreOf<UserProfileFeature>

	public init(_ store: StoreOf<UserProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		switch store.state {
		case .external:
			CocoaComponent {
				ExternalUserProfileController(store: store.scope(
					state: \.external,
					action: \.external
				))
			}
			.background(Color(.systemPink).ignoresSafeArea(edges: .top))

		case .current:
			CocoaComponent {
				CurrentUserProfileController(store: store.scope(
					state: \.current,
					action: \.current
				))
			}
			.background(Color(.systemOrange).ignoresSafeArea(edges: .top))

		case .loading:
			ProgressView()
		}
	}
}
