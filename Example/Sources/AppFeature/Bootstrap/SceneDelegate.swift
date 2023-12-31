//
//  SceneDelegate.swift
//  Example
//
//  Created by Maxim Krouk on 11.11.2023.
//

import _ComposableArchitecture
import AppUI
import AppModels
import MainFeature
import DatabaseSchema
import LocalExtensions

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	public var window: UIWindow?

	public func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let scene = scene as? UIWindowScene else { return }

		let controller = MainViewController()

		let window = UIWindow(windowScene: scene)
		self.window = window

		window.rootViewController = controller

		window.makeKeyAndVisible()

		Task { @MainActor in
			try await prefillDatabaseIfNeeded(autoSignIn: true)

			controller.setStore(Store(
				initialState: .init(),
				reducer: {
					MainFeature()._printChanges()
				}
			))
		}
	}

	public func sceneDidDisconnect(_ scene: UIScene) {}
	public func sceneDidBecomeActive(_ scene: UIScene) {}
	public func sceneWillResignActive(_ scene: UIScene) {}
	public func sceneWillEnterForeground(_ scene: UIScene) {}
	public func sceneDidEnterBackground(_ scene: UIScene) {}
}

