import _ComposableArchitecture
import SwiftUI
import AppModels
import AuthFeature
import CurrentUserProfileFeature
import CocoaExtensions
@_spi(Internals) import CombineNavigation
import CocoaAliases
import ComposableExtensionsCore

public struct ProfileTabView: ComposableView {
	private let store: StoreOf<ProfileTabFeature>

	@Environment(\.colorTheme)
	var color

	public init(_ store: StoreOf<ProfileTabFeature>) {
		self.store = store
	}

	public var body: some View {
		ZStack {
			switch store.root {
			case .profile:
				CocoaComponent {
					CurrentUserProfileController().configured { $0
						.set {
							$0.setStore(store.__scope(
								state: \.root.profile,
								action: \.root.profile
							))
						}
					}
				 }
				.toolbar {
					ToolbarItemGroup(placement: .topBarTrailing) {
						Button(action: { store.send(.root(.profile(.openSettings))) }) {
							Image(systemName: "gear")
						}
					}
				}
				.toolbarRole(.navigationStack)
				.background(Color(.systemOrange).ignoresSafeArea(edges: .top))
				.onAppear { Swift.print("dr:appear:p") }

			case .auth:
				AuthView?(store.scope(
					state: \.root.auth,
					action: \.root.auth
				))
				.onAppear { Swift.print("dr:appear:a") }
			}
		}
	}
}

@_spi(Internals) import ComposableArchitecture

extension Store where State: ObservableState {
  public func __scope<ChildState, ChildAction>(
    state: KeyPath<State, ChildState?>,
    action: CaseKeyPath<Action, ChildAction>
  ) -> Store<ChildState?, ChildAction> {
    return self.scope(
      id: self.id(state: state, action: action),
      state: ToState(state),
      action: { action($0) },
      isInvalid: { $0[keyPath: state] == nil }
    )
  }
}
