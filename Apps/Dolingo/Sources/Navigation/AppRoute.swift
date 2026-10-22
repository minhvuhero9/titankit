import Foundation
import TitanNavigation

/// Every screen Dolingo can push or present. Grows as screens are added.
enum AppRoute: Routable {
    case catalog
    case settings
    case appearance
    case webPage(WebPage)
}

/// Pages Dolingo shows in a web view.
enum WebPage: String, Sendable {
    case privacy, terms
}

/// dolingo://catalog, dolingo://settings
struct DolingoDeepLinkParser: DeepLinkParser {
    func link(from url: URL) -> DeepLink<AppRoute>? {
        guard url.scheme == AppConfig.urlScheme else { return nil }
        switch url.deepLinkSegments().first {
        case "catalog": return DeepLink(route: .catalog)
        case "settings": return DeepLink(route: .settings)
        default: return nil
        }
    }
}
