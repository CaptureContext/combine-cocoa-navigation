import CocoaAliases
import CombineNavigation
import DeclarativeConfiguration

extension PresentationDestinationContainerProvider {
	@inlinable
	public func container(_ configuration: (CocoaViewController.Config) -> CocoaViewController.Config) -> Self {
		container(configuration(CocoaViewController.Config()))
	}

	@inlinable
	public func container(_ configurator: CocoaViewController.Config) -> Self {
			.init { controller in
				let container = self.callAsFunction(controller)
				configurator.configure(container)
				return container
			}
	}
}
