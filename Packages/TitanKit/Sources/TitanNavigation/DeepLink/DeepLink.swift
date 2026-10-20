import Foundation

/// A route read from a URL, and how to show it.
public struct DeepLink<Route: Routable>: Hashable, Sendable {
    public enum Presentation: Hashable, Sendable {
        case push, sheet, fullScreen
    }

    public let route: Route
    public let presentation: Presentation

    public init(route: Route, presentation: Presentation = .push) {
        self.route = route
        self.presentation = presentation
    }
}

/// Turns a URL into a DeepLink. Each app writes one; the handler is shared.
public protocol DeepLinkParser: Sendable {
    associatedtype Route: Routable
    /// nil for URLs the app does not understand.
    func link(from url: URL) -> DeepLink<Route>?
}

public extension URL {
    /// Path parts with the host in front for custom schemes, so `dolingo://lesson/42` and
    /// `https://dolingo.app/lesson/42` both give `["lesson", "42"]`.
    func deepLinkSegments(webHosts: Set<String> = []) -> [String] {
        let parts = pathComponents.filter { $0 != "/" }
        let isWeb = scheme == "http" || scheme == "https"
        if isWeb {
            guard let host, webHosts.isEmpty || webHosts.contains(host) else { return [] }
            return parts
        }
        return (host.map { [$0] } ?? []) + parts
    }

    /// Query items as a dictionary; the last value wins for repeated names.
    var queryParameters: [String: String] {
        let items = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return items.reduce(into: [:]) { result, item in result[item.name] = item.value }
    }
}
