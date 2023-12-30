import _ComposableArchitecture
import UIKit
import SwiftUI
import Combine
import CombineExtensions
import Capture
import CombineNavigation
import DeclarativeConfiguration
import AppUI

#warning("Implement ProfileTabController")
@RoutingController
public final class ProfileTabController: ComposableViewControllerOf<ProfileTabFeature> {
	let label: UILabel = .init { $0
		.translatesAutoresizingMaskIntoConstraints(false)
		.textColor(ColorTheme.current.label.primary)
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		view.backgroundColor = ColorTheme.current.background.primary
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.store?.send(.event(.didAppear))
	}

	public override func scope(_ store: Store?) {

	}

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Set<AnyCancellable>
	) {
		publisher.root
			.sinkValues(capture { _self, root in
				switch root {
				case .auth(.signIn):
					_self.label.text = "Sign In"
				case .auth(.signUp):
					_self.label.text = "Sign Up"
				case let .profile(state):
					_self.label.text = state.model.username
				}
			})
			.store(in: &cancellables)
	}
}
