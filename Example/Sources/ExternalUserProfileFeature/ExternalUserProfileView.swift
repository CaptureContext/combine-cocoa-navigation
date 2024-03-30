import _ComposableArchitecture
import SwiftUI
import AppModels
import TweetsFeedFeature
import UserSettingsFeature
import CocoaExtensions
import AppUI

public struct ExternalUserProfileView: ComposableView {
	private let store: StoreOf<ExternalUserProfileFeature>

	@Environment(\.colorTheme)
	var color

	public init(_ store: StoreOf<ExternalUserProfileFeature>) {
		self.store = store
	}

	public var body: some View {
		GeometryReader { proxy in
			ScrollView(.vertical) {
				VStack {
					headerView
						.offset(y: -24)
						.padding(.bottom, 8)
						.padding(.horizontal)
					Divider()
						.padding(.bottom, 32)
					tweetsView
				}
				.background(color(\.background))
				.padding(.top, 64)
				.frame(
					minWidth: proxy.size.width,
					minHeight: proxy.size.height,
					maxHeight: .infinity
				)
			}
			.background(VStack { // emulate sticky header
				Color(.systemPink).frame(height: proxy.size.height / 2)
				Spacer()
			})
		}
	}

	@ViewBuilder
	var headerView: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack(alignment: .bottom) {
				Circle()
					.fill(color(\.background))
					.stroke(color(\.label))
					.frame(width: 64, height: 64)
					.onTapGesture {
						store.send(.tapOnAvatar)
					}
				Spacer()
				Button(action: { store.send(.tapFollow) }) {
					Text(store.model.isFollowedByYou ? "Unfollow" : "Follow")
						.scaledFont(ofSize: 12, weight: .semibold)
						.padding(.horizontal, 32)
						.padding(.vertical, 10)
						.foregroundStyle(color(\.background))
						.background(color(\.label))
						.clipShape(Capsule())
				}
			}
			VStack(alignment: .leading, spacing: 8) {
				Text(store.model.displayName)
					.scaledFont(ofSize: 18, weight: .semibold)
					.foregroundStyle(color(\.label))
				Text("@" + store.model.username.lowercased())
					.scaledFont(ofSize: 12, design: .monospaced)
					.foregroundStyle(color(\.label.secondary))
			}
			VStack(alignment: .leading, spacing: 10) {
				if store.model.bio.isNotEmpty {
					Text(store.model.bio)
						.scaledFont(ofSize: 14)
						.tint(color(\.label))
				}
				HStack(spacing: 10) {
					HStack(spacing: 3) {
						Text(store.model.followsCount.description)
							.scaledFont(ofSize: 10, weight: .semibold, design: .monospaced)
							.foregroundStyle(color(\.label))
						Text("Following")
							.scaledFont(ofSize: 10)
							.foregroundStyle(color(\.label.secondary))
					}
					HStack(spacing: 3) {
						Text(store.model.followersCount.description)
							.scaledFont(ofSize: 10, weight: .semibold, design: .monospaced)
							.foregroundStyle(color(\.label))
						Text("Followers")
							.scaledFont(ofSize: 10)
							.foregroundStyle(color(\.label.secondary))
					}
					Spacer()
				}
			}
		}
	}

	@ViewBuilder
	var tweetsView: some View {
		CocoaComponent {
			TweetsFeedController(store: store.scope(
				state: \.feed,
				action: \.feed
			))
		}
	}
}
