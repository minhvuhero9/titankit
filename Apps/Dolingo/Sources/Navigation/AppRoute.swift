import Foundation
import TitanNavigation

/// Every screen Dolingo can push or present. Grows as screens are added.
enum AppRoute: Routable {
    case catalog
}

/// dolingo://catalog
struct DolingoDeepLinkParser: DeepLinkParser {
    func link(from url: URL) -> DeepLink<AppRoute>? {
        guard url.scheme == AppConfig.urlScheme else { return nil }
        switch url.deepLinkSegments().first {
        case "catalog": return DeepLink(route: .catalog)
        default: return nil
        }
    }
}
