import _ComposableArchitecture
import Foundation
import AppModels
import TweetsListFeature
import UserSettingsFeature

@Reducer
public struct CurrentUserProfileFeature {
	public init() {}

	@Reducer
	public struct Destination {
		@ObservableState
		public enum State: Equatable {
			case avatarPreivew(URL)
			case userSettings(UserSettingsFeature.State)
		}

		public enum Action: Equatable {
			case avatarPreivew(Never)
			case userSettings(UserSettingsFeature.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: \.avatarPreivew,
				action: \.avatarPreivew,
				child: EmptyReducer.init
			)
			Scope(
				state: \.userSettings,
				action: \.userSettings,
				child: UserSettingsFeature.init
			)
		}
	}

	@ObservableState
	public struct State: Equatable {
		public var model: UserModel
		public var tweetsList: TweetsListFeature.State

		@Presents
		public var destination: Destination.State?

		public init(
			model: UserModel,
			tweetsList: TweetsListFeature.State = .init(),
			destination: Destination.State? = nil
		) {
			self.model = model
			self.tweetsList = tweetsList
			self.destination = destination
		}
	}

	public enum Action: Equatable {
		case destination(PresentationAction<Destination.Action>)
		case tweetsList(TweetsListFeature.Action)
		case tapOnAvatar
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .tapOnAvatar:
				guard let avatarURL = state.model.avatarURL
				else { return .none}
				state.destination = .avatarPreivew(avatarURL)
				return .none

			default:
				return .none
			}
		}
		.ifLet(
			\State.$destination,
			action: \.destination,
			destination: Destination.init
		)

		Scope(
			state: \State.tweetsList,
			action: \.tweetsList,
			child: TweetsListFeature.init
		)
	}
}
