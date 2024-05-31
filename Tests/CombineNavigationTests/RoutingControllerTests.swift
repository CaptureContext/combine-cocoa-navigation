import XCTest
import CocoaAliases
import Capture
import Combine
import CustomDump
import CombineExtensions
@_spi(Internals) @testable import CombineNavigation

#if canImport(UIKit) && !os(watchOS)
import SwiftUI

// TODO: Add test for `navigationStack(_:ids:route:switch:onDismiss:)`")
// TODO: Add test for `navigationDestination(_:isPresented:controller:onDismiss:)`")
final class RoutingControllerTests: XCTestCase {
	static override func setUp() {
		CombineNavigation.bootstrap()
	}

	func testDeinit() {
		withoutNavigationAnimation {
			let root = TreeViewController()
			let viewModel = TreeViewModel()
			let navigation = UINavigationController(rootViewController: root)
			var expectations: [XCTestExpectation] = []

			root.viewModel = viewModel

			// Ensure unreferenced objects are deallocated
			// before performing assertion
			autoreleasepool {
				do {
					let expectation = expectation(description: "plain")
					var controller: TreeViewController? = .init()
					controller?.onDeinit = expectation.fulfill
					expectations.append(expectation)
					controller = nil
				}

				do {
					let expectation = expectation(description: "tree.stack")
					viewModel.state.destination = .stack()
					root.stackController!.onDeinit = expectation.fulfill
					expectations.append(expectation)
				}

				do {
					let expectation = expectation(description: "tree.stack.path")
					viewModel.state.destination!.stack!.state.path.append(.tree())
					root.stackController?.treeControllers[
						root.stackController!.treeControllers.keys.first!
					]?.onDeinit = expectation.fulfill
					expectations.append(expectation)
				}

				do {
					navigation.popViewController()
					navigation.popViewController()
				}
			}

			XCTAssertEqual(root.treeController, nil)
			wait(for: expectations, timeout: 1)
		}
	}

	func testLive() {
		customDump(NavigationStateNode.example)
		NavigationStateNode.example.print()
		customDump(collectNavigationStack(from: .example).map { $0.uuidString.lowercased() })
		customDump(collectPresentationStack(from: .example).map { $0.uuidString.lowercased() })
		print()
		print()
		print()
		withoutNavigationAnimation {
			let root = StackViewController()
			let viewModel = StackViewModel()
			let navigation = UINavigationController(rootViewController: root)
			navigation.loadViewIfNeeded()
			root.loadViewIfNeeded()

			root.viewModel = viewModel

			XCTAssertEqual(navigation.viewControllers.count, 1)

			do {
				var stdout = ""
				root.combineNavigationRouter.printRoutersGraph(to: &stdout)
				print(stdout)
			}

			root.withRoutersGraphDiff {
				root.viewModel?.state.root.state.destination = .tree(.init(
					initialState: .init(destination: .tree(.init(
						initialState: .init(destination: .tree(.init(
							initialState: .init()
						)))
					)))
				))
			}

			print("assert")
			XCTAssertEqual(navigation.viewControllers.count, 4)

			root.withRoutersGraphDiff {
				root.viewModel?.state.path.append(.tree(.init(
					initialState: .init()
				)))
			}

			XCTAssertEqual(navigation.viewControllers.count, 5)
		}
	}

	func testMain() {
		let log: () -> Void = {
			var count = 0
			return { print("\n::\(count)"); count += 1 }
		}()

		withoutNavigationAnimation {
			let root = StackViewController()
			let navigation = UINavigationController(rootViewController: root)

			do { log() // deeplinking
				root.viewModel = StackViewModel(initialState: .init(
					root: .init(initialState: .init(
						destination: .tree()
					))
				))

				XCTAssertEqual(navigation.viewControllers.count, 2)
			}

			do { log() // navigation tree: batch set
				root.withRoutersGraphDiff {
					root.viewModel?.state.root.state.destination?.tree?.state.destination = .tree(.init(
						initialState: .init(destination: .tree()
					)))
				}

				XCTAssertEqual(navigation.viewControllers.count, 4)
			}

			do { log() // navigation tree: pop
				root.withRoutersGraphDiff {
					navigation.popViewController()
				}

				XCTAssertEqual(navigation.viewControllers.count, 3)

				XCTAssertNotNil(
					root.contentController?
						.treeController?
						.treeController
				)

				XCTAssertNotNil(
					root.viewModel?.state.root
						.state.destination?.tree?
						.state.destination
				)

				XCTAssertNil(
					root.viewModel?.state.root
						.state.destination?.tree?
						.state.destination?.tree?
						.state.destination
				)

				// Destination should be invalidated
				// Controller should be nil
				XCTAssertNil(
					root.contentController?
						.treeController?
						.treeController?
						.treeController
				)
			}

			do { log() // stack navigation
				root.withRoutersGraphDiff {
					root.viewModel?.state.path.append(.tree())
				}

				XCTAssertEqual(navigation.viewControllers.count, 4)

				root.withRoutersGraphDiff {
					navigation.popViewController()
				}

				XCTAssertEqual(navigation.viewControllers.count, 3)

				XCTAssertEqual(root.viewModel?.state.path.count, 0)
			}

			do { log() // navigation tree: reset
				root.withRoutersGraphDiff {
					root.viewModel?.state.root.state.destination = nil
				}

				XCTAssertEqual(navigation.viewControllers.count, 1)
			}
		}
	}
}

fileprivate class TreeViewModel: ViewModelProtocol {
	struct State {
		enum Destination {
			case tree(TreeViewModel = .init())
			case stack(StackViewModel = .init())

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

	init(initialState: State = .init()) {
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
fileprivate class TreeViewController: MVVMController<TreeViewModel> {

	@TreeDestination
	var treeController: TreeViewController?

	@TreeDestination
	var stackController: StackViewController?

	override func scope(_ viewModel: TreeViewModel?) {
		super.scope(viewModel)

		$treeController.setConfiguration { controller in
			controller.viewModel = viewModel?.state.destination?.tree
		}

		$stackController.setConfiguration { controller in
			controller.viewModel = viewModel?.state.destination?.stack
		}
	}

	override func bind(
		_ publisher: TreeViewModel.StatePublisher
	) {
		super.bind(publisher)

		navigationDestination(
			publisher.map(\.destination),
			switch: { destinations, route in
				switch route {
				case .tree:
					destinations.$treeController
				case .stack:
					destinations.$stackController
				}
			},
			onPop: { [weak self] in
				print(self?.objectID as Any, "onPop")
				self?.viewModel?.state.destination = .none
			}
		)
		.store(in: &cancellables)
	}
}

// MARK: - Stack

fileprivate class StackViewModel: ViewModelProtocol {
	struct State {
		enum Destination {
			case tree(TreeViewModel = .init())
			case stack(StackViewModel = .init())

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

	init(initialState: State = .init()) {
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
fileprivate class StackViewController: MVVMController<StackViewModel> {
	@DerivedDestination
	var contentController: TreeViewController?

	@StackDestination
	var treeControllers: [Int: TreeViewController]

	@StackDestination
	var stackControllers: [Int: StackViewController]

	override func viewDidLoad() {
		super.viewDidLoad()
		addChild(_contentController())
		contentController.map { controller in
			view.addSubview(controller.view)
			controller.view.frame = view.bounds
			controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			controller.didMove(toParent: self)
		}
	}

	override func scope(_ viewModel: StackViewModel?) {
		super.scope(viewModel)

		$contentController.setConfiguration { controller in
			controller.viewModel = viewModel?.state.root
		}

		$treeControllers.setConfiguration { controller, id in
			controller.viewModel = viewModel?.state.path[safe: id]?.tree
		}

		$stackControllers.setConfiguration { controller, id in
			controller.viewModel = viewModel?.state.path[safe: id]?.stack
		}
	}

	override func bind(
		_ publisher: StackViewModel.StatePublisher
	) {
		super.bind(publisher)

		navigationStack(
			publisher.map(\.path).map { $0.map(\.tag) },
			switch: { destinations, route in
				switch route {
				case .tree:
					destinations.$treeControllers
				case .stack:
					destinations.$stackControllers
				}
			},
			onPop: capture { _self, indices in
				_self.viewModel?.state.path.remove(atOffsets: IndexSet(indices))
			}
		)
		.store(in: &cancellables)
	}
}

extension UIViewController {
	func withRoutersGraphDiff(perform operation: () -> Void) {
		var output = (old: "", new: "")
		combineNavigationRouter.printRoutersGraph(to: &output.old)
		operation()
		combineNavigationRouter.printRoutersGraph(to: &output.new)
		print(diff(output.old, output.new) ?? "-")
	}
}

protocol ViewModelProtocol {
	associatedtype State
	associatedtype StatePublisher: Publisher where StatePublisher.Output == State

	var state: State { get set }
	var publisher: StatePublisher { get }
}

class MVVMController<ViewModel: ViewModelProtocol>: CocoaViewController {
	var cancellables: Set<AnyCancellable> = []
	var onDeinit: (() -> Void)?

	var viewModel: ViewModel? {
		didSet {
			cancellables = []
			scope(viewModel)
			viewModel.map(\.publisher).map(bind)
		}
	}

	open func scope(_ viewModel: ViewModel?) {
		print(ObjectIdentifier(self), #function)
	}

	open func bind(_ publisher: ViewModel.StatePublisher) {
		print(ObjectIdentifier(self), #function)
	}

	deinit {
		print("deinit vc", objectID)
		onDeinit?()
	}
}


#endif
