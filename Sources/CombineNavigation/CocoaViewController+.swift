#if canImport(UIKit) && !os(watchOS)
import CocoaAliases
import Combine
import CombineExtensions
import FoundationExtensions

fileprivate extension Cancellable {
  func store(in cancellable: inout Cancellable?) {
    cancellable = self
  }
}

extension CocoaViewController {
  var __dismissCancellables: Set<AnyCancellable> {
    set { setAssociatedObject(newValue, forKey: #function) }
    get { getAssociatedObject(forKey: #function).or([]) }
  }

  public func configureRoute<
    P: Publisher,
    Route: ExpressibleByNilLiteral & Hashable
  >(
    for publisher: P,
    onDismiss: @escaping () -> Void = {}
  ) -> Cancellable where P.Output == Route, P.Failure == Never {
    publisher
      .removeDuplicates()
      .receive(on: UIScheduler.shared)
      .sink { [weak self] route in
        guard let self = self else { return }
        
        let destination = self
          .erasedRouteConfigurations
          .first { $0.target == AnyHashable(route) }
          .map { $0.getController }
        
        self.navigate(
          to: destination,
          beforePush: { controller in
            self.configureNavigationDismiss(onDismiss)
              .store(in: &controller.__dismissCancellables)
          }
        )
      }
  }
  
  public func configureRoutes<
    P: Publisher,
    Route: ExpressibleByNilLiteral & Hashable
  >(
    for publisher: P,
    routes: [RouteConfiguration<Route>],
    onDismiss: @escaping () -> Void = {}
  ) -> Cancellable where P.Output == Route, P.Failure == Never {
    publisher
      .removeDuplicates()
      .receive(on: UIScheduler.shared)
      .sink { [weak self] route in
        guard let self = self else { return }
        let destination = routes
          .first { $0.target == route }
          .map { $0.getController }
          .or(
            self
              .erasedRouteConfigurations
              .first { $0.target == AnyHashable(route) }
              .map { $0.getController }
          )
          
        self.navigate(
          to: destination,
          beforePush: { controller in
            self.configureNavigationDismiss(onDismiss)
              .store(in: &controller.__dismissCancellables)
          }
        )
      }
  }
  
  private func navigate(
    to destination: (() -> CocoaViewController)?,
    beforePush: (CocoaViewController) -> Void
  ) {
    guard let navigationController = self.navigationController
    else { return }
    
    let isDismiss = destination == nil
    && navigationController.visibleViewController !== self
    
    if isDismiss {
      guard navigationController.viewControllers.contains(self) else {
        navigationController.popToRootViewController(animated: true)
        return
      }
      navigationController.popToViewController(self, animated: true)
    } else if let destination = destination {
      let controller = destination()
      
      if navigationController.viewControllers.contains(self) {
        if navigationController.viewControllers.last !== self {
          navigationController.popToViewController(self, animated: false)
        }
      }
      
      beforePush(controller)
      navigationController.pushViewController(controller, animated: true)
    }
  }
  
  private func configureNavigationDismiss(
    _ action: @escaping () -> Void
  ) -> Cancellable {
    let localRoot = navigationController?.topViewController
    
    let first = navigationController?
      .publisher(for: #selector(UINavigationController.popViewController))
      .receive(on: UIScheduler.shared)
      .sink { [weak self, weak localRoot] in
        guard
          let self = self,
          let localRoot = localRoot,
          self.navigationController?.visibleViewController === localRoot
        else { return }
        if let coordinator = self.navigationController?.transitionCoordinator {
          coordinator.animate(alongsideTransition: nil) { context in
            if !context.isCancelled { action() }
          }
        } else {
          action()
        }
      }
    
    let second: Cancellable? = navigationController?
      .publisher(for: #selector(UINavigationController.popToViewController))
      .receive(on: UIScheduler.shared)
      .sink { [weak self] in
        guard
          let self = self,
          let navigationController = self.navigationController,
          !navigationController.viewControllers.contains(self)
        else { return }
        if let coordinator = self.navigationController?.transitionCoordinator {
          coordinator.animate(alongsideTransition: nil) { context in
            if !context.isCancelled { action() }
          }
        } else {
          action()
        }
      }
    
    let third = navigationController?
      .publisher(for: #selector(UINavigationController.popToRootViewController))
      .receive(on: UIScheduler.shared)
      .sink { action() }
    
    let cancellable = AnyCancellable {
      first?.cancel()
      second?.cancel()
      third?.cancel()
    }
    
    return cancellable
  }
}
#endif
