import XCTest
import CocoaAliases
import Capture
import Combine
import CombineSchedulers
@testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

// TODO: Add test for `navigationStack(_:ids:route:switch:onDismiss:)`")
// TODO: Add test for `navigationDestination(_:isPresented:controller:onDismiss:)`")
final class RoutingControllerTests: XCTestCase {
	static override func setUp() {
		CombineNavigation.bootstrap()
	}

	func testMain() {
		let root = StackViewController()
		let viewModel = StackViewModel(initialState: .init())
		let navigation = UINavigationController(rootViewController: root)
		navigation.loadViewIfNeeded()
		root.loadViewIfNeeded()
		root.viewModel = viewModel

		withoutNavigationAnimation {
			XCTAssertEqual(navigation.viewControllers.count, 1)

			root.viewModel.state.root.state.destination = .tree(.init(
				initialState: .init(destination: .tree(.init(
					initialState: .init(destination: .tree(.init(
						initialState: .init()
					)))
				)))
			))
			XCTAssertEqual(navigation.viewControllers.count, 4)

			root.viewModel.state.path.append(.tree(.init(
				initialState: .init()
			)))
			XCTAssertEqual(navigation.viewControllers.count, 5)

			navigation.popViewController()
			XCTAssertEqual(navigation.viewControllers.count, 4)
			XCTAssertEqual(root.viewModel.state.path.count, 0)
			XCTAssertNotNil(
				root.viewModel.state.root
					.state.destination?.tree?
					.state.destination?.tree?
					.state.destination?.tree
			)

			root.viewModel.state.root
				.state.destination?.tree?
				.state.destination = .tree(.init(initialState: .init()))

			XCTAssertNil(
				root.viewModel.state.root
					.state.destination?.tree?
					.state.destination?.tree?
					.state.destination?.tree
			)

			XCTAssertEqual(navigation.viewControllers.count, 3)

			navigation.popViewController()
			XCTAssertNil(
				root.viewModel.state.root
					.state.destination?.tree?
					.state.destination?.tree
			)
		}
	}
}

fileprivate class TreeViewModel {
	struct State {
		enum Destination {
			/// UUID represents some state
			case tree(TreeViewModel)
			case stack(StackViewModel)

			enum Tag: Hashable {
				case tree
				case stack
			}

			var tree: TreeViewModel? {
				switch self {
				case let .tree(viewModel):
					viewModel
				default:
					nil
				}
			}

			var stack: StackViewModel? {
				switch self {
				case let .stack(viewModel):
					viewModel
				default:
					nil
				}
			}

			var tag: Tag {
				switch self {
				case .tree: return .tree
				case .stack: return .stack
				}
			}
		}

		var id: UUID = .init()
		var destination: Destination?
	}

	init(initialState: State) {
		self._state = .init(initialState)
	}

	private let _state: CurrentValueSubject<State, Never>
	public var state: State {
		get { _state.value }
		set { _state.value = newValue }
	}

	var publisher: some Publisher<State, Never> {
		_state
	}
}

@RoutingController
fileprivate class TreeViewController: CocoaViewController {
	private var cancellables: Set<AnyCancellable> = []

	var viewModel: TreeViewModel! {
		didSet {
			cancellables = []
			guard let viewModel else { return }
			bind(viewModel.publisher)
		}
	}

	@TreeDestination
	var treeController: TreeViewController?

	@TreeDestination
	var stackController: StackViewController?

	func scope(_ viewModel: TreeViewModel?) {
		$treeController.setConfiguration { controller in
			controller.viewModel = viewModel?.state.destination?.tree
		}

		$stackController.setConfiguration { controller in
			controller.viewModel = viewModel?.state.destination?.stack
		}
	}

	func bind(
		_ publisher: some Publisher<TreeViewModel.State, Never>
	) {
		publisher.map(\.destination).removeDuplicates { lhs, rhs in
			lhs.flatMap(\.tree).map(ObjectIdentifier.init)
			== rhs.flatMap(\.tree).map(ObjectIdentifier.init)
			&&
			lhs.flatMap(\.stack).map(ObjectIdentifier.init)
			== rhs.flatMap(\.stack).map(ObjectIdentifier.init)
		}.sinkValues(capture { _self, destination in
			self.scope(_self.viewModel)
		})
		.store(in: &cancellables)

		navigationDestination(
			publisher.map(\.destination?.tag).removeDuplicates(),
			switch: { destinations, route in
				switch route {
				case .tree:
					destinations.$treeController
				case .stack:
					destinations.$stackController
				}
			},
			onPop: capture { _self in
				_self.viewModel.state.destination = .none
			}
		)
		.store(in: &cancellables)
	}
}

// MARK: - Stack

fileprivate class StackViewModel {
	struct State {
		enum Destination {
			/// UUID represents some state
			case tree(TreeViewModel)
			case stack(StackViewModel)

			enum Tag: Hashable {
				case tree
				case stack
			}

			var tree: TreeViewModel? {
				switch self {
				case let .tree(viewModel):
					viewModel
				default:
					nil
				}
			}

			var stack: StackViewModel? {
				switch self {
				case let .stack(viewModel):
					viewModel
				default:
					nil
				}
			}

			var tag: Tag {
				switch self {
				case .tree: return .tree
				case .stack: return .stack
				}
			}
		}

		var root: TreeViewModel = .init(initialState: .init())
		var path: [Destination] = []
	}

	init(initialState: State) {
		self._state = .init(initialState)
	}

	private let _state: CurrentValueSubject<State, Never>
	public var state: State {
		get { _state.value }
		set { _state.value = newValue }
	}

	var publisher: some Publisher<State, Never> {
		_state
	}
}

@RoutingController
fileprivate class StackViewController: CocoaViewController {
	private var cancellables: Set<AnyCancellable> = []

	var viewModel: StackViewModel! {
		didSet {
			cancellables = []
			guard let viewModel else { return }
			bind(viewModel.publisher)
		}
	}

	var contentController: TreeViewController = .init()

	@StackDestination
	var treeControllers: [Int: TreeViewController]

	@StackDestination
	var stackControllers: [Int: StackViewController]

	override func viewDidLoad() {
		super.viewDidLoad()
		addRoutedChild(contentController)
		view.addSubview(contentController.view)
		contentController.view.frame = view.bounds
		contentController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		contentController.didMove(toParent: self)
	}

	func scope(_ viewModel: StackViewModel?) {
		contentController.viewModel = viewModel?.state.root

		$treeControllers.setConfiguration { controller, id in
			controller.viewModel = viewModel?.state.path[safe: id]?.tree
		}

		$stackControllers.setConfiguration { controller, id in
			controller.viewModel = viewModel?.state.path[safe: id]?.stack
		}
	}

	func bind(
		_ publisher: some Publisher<StackViewModel.State, Never>
	) {
		publisher.map(\.path).removeDuplicates { lhs, rhs in
			lhs.compactMap(\.tree).map(ObjectIdentifier.init)
			== rhs.compactMap(\.tree).map(ObjectIdentifier.init)
			&&
			lhs.compactMap(\.stack).map(ObjectIdentifier.init)
			== rhs.compactMap(\.stack).map(ObjectIdentifier.init)
		}.sinkValues(capture { _self, destination in
			self.scope(_self.viewModel)
		})
		.store(in: &cancellables)

		navigationStack(
			publisher.map(\.path).map { $0.map(\.tag) }.removeDuplicates(),
			switch: { destinations, route in
				switch route {
				case .tree:
					destinations.$treeControllers
				case .stack:
					destinations.$stackControllers
				}
			},
			onPop: capture { _self, indices in
				_self.viewModel.state.path.remove(atOffsets: IndexSet(indices))
			}
		)
		.store(in: &cancellables)
	}

}
#endif
