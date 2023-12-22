//
//  SceneDelegate.swift
//  Example
//
//  Created by Maxim Krouk on 11.11.2023.
//

import _ComposableArchitecture
import UIKit
import CombineNavigation
import AppFeature

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	let store = Store(
		initialState: FeedTabFeature.State(
			feed: .init(
				list: .init(
					tweets: .init(
						uncheckedUniqueElements: TweetModel
							.mockTweets.filter(\.replyTo.isNil)
							.map { .mock(model: $0) }
					)
				)
			)
		),
		reducer: {
			FeedTabFeature()._printChanges()
		}
	)

	func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		guard let scene = scene as? UIWindowScene else { return }
		let controller = FeedTabController()
		controller.setStore(store)

		let window = UIWindow(windowScene: scene)
		self.window = window

		window.rootViewController = UINavigationController(
			rootViewController: controller
		)

		window.makeKeyAndVisible()
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
}

