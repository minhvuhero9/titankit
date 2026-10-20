import SwiftUI

/// Holds where the user is in one navigation stack: the pushed screens and any sheet or cover.
/// Views and view models call it instead of building destination screens themselves.
@MainActor
public final class Router<Route: Routable>: ObservableObject {
    @Published public var path: [Route]
    @Published public var sheet: Route?
    @Published public var fullScreenCover: Route?

    public init(path: [Route] = []) {
        self.path = path
    }

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        _ = path.popLast()
    }

    public func popToRoot() {
        path.removeAll()
    }

    public func present(_ route: Route, fullScreen: Bool = false) {
        if fullScreen {
            fullScreenCover = route
        } else {
            sheet = route
        }
    }

    public func dismiss() {
        sheet = nil
        fullScreenCover = nil
    }

    /// Opens a deep link: closes anything presented, then pushes or presents the route.
    public func open(_ link: DeepLink<Route>) {
        dismiss()
        switch link.presentation {
        case .push: push(link.route)
        case .sheet: present(link.route)
        case .fullScreen: present(link.route, fullScreen: true)
        }
    }
}
