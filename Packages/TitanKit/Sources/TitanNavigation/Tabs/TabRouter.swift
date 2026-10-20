import SwiftUI

/// The selected tab plus one Router per tab, so each tab keeps its own stack.
@MainActor
public final class TabRouter<Tab: Hashable & CaseIterable & Sendable, Route: Routable>: ObservableObject {
    @Published public var selected: Tab
    public let routers: [Tab: Router<Route>]

    public init(initial: Tab) {
        selected = initial
        routers = Dictionary(uniqueKeysWithValues: Tab.allCases.map { ($0, Router<Route>()) })
    }

    public func router(for tab: Tab) -> Router<Route> {
        guard let router = routers[tab] else {
            preconditionFailure("TabRouter has no router for \(tab)")
        }
        return router
    }

    /// Switches to `tab` and opens the link there.
    public func open(_ link: DeepLink<Route>, in tab: Tab) {
        selected = tab
        router(for: tab).open(link)
    }

    /// Tapping the selected tab again goes back to its first screen, like most iOS apps.
    public func select(_ tab: Tab) {
        if tab == selected {
            router(for: tab).popToRoot()
        }
        selected = tab
    }
}
