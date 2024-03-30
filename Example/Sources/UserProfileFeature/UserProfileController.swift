import _ComposableArchitecture
import UIKit
import SwiftUI
import Combine
import CombineExtensions
import Capture
import CombineNavigation
import DeclarativeConfiguration
import AppUI

@RoutingController
public final class UserProfileController: ComposableHostingController<UserProfileView> {
	public override func viewDidLoad() {
		super.viewDidLoad()

		let appearance = UINavigationBarAppearance()
		appearance.configureWithTransparentBackground()
		navigationItem.standardAppearance = appearance
		navigationItem.compactAppearance = appearance
		navigationItem.scrollEdgeAppearance = appearance
		navigationItem.compactScrollEdgeAppearance = appearance
	}

	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.store?.send(.event(.didAppear))
	}
}
