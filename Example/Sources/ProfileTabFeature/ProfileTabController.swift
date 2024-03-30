import _ComposableArchitecture
import UIKit
import SwiftUI
import Combine
import CombineExtensions
import Capture
import CombineNavigation
import DeclarativeConfiguration
import AppUI

@_spi(Internals) @testable import ComposableArchitecture

@RoutingController
public final class ProfileTabController: ComposableHostingController<ProfileTabView> {
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

	public override func bind(
		_ publisher: StorePublisher,
		into cancellables: inout Cancellables
	) {
		store!.rootStore.didSet
			.sinkValues(capture { _self in
				print("dr:profile:", _self.store?.root.profile?.model.id ?? "nil")
			})
			.store(in: &cancellables)
	}
}
