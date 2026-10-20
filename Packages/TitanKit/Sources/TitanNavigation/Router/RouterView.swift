import SwiftUI

/// A NavigationStack driven by a Router. `destination` builds the screen for each route,
/// for pushes, sheets and full-screen covers alike.
///
///     RouterView(router: router) {
///         HomeView()
///     } destination: { route in
///         container.makeView(for: route)
///     }
public struct RouterView<Route: Routable, Root: View, Destination: View>: View {
    @ObservedObject private var router: Router<Route>
    private let root: Root
    private let destination: (Route) -> Destination

    public init(
        router: Router<Route>,
        @ViewBuilder root: () -> Root,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.router = router
        self.root = root()
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            root.navigationDestination(for: Route.self, destination: destination)
        }
        .sheet(item: $router.sheet, content: destination)
        .fullScreenCover(item: $router.fullScreenCover, content: destination)
        .environmentObject(router)
    }
}
