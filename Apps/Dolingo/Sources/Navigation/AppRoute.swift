import Foundation
import TitanNavigation

/// Every screen Dolingo can push or present. Grows as screens are added.
enum AppRoute: Routable {
    case catalog
    case settings
    case appearance
    case profile
    case deleteAccount
    case paywall
    case webPage(WebPage)
    case lesson(id: String)
    /// Figma "roleplay - meeting new friends": scenario, goal and tasks before starting.
    case roleplay(Roleplay)
    case roleplayChat(Roleplay)
    /// Figma "speaking practice": one Speak topic, phrase by phrase, full screen.
    case phrasePractice(PhraseCategory)
    case savedPhrases
    /// Settings sub-screens (Figma 94, 96, 97, 98, 107–109).
    case preferences, notifications, security, billing, help, faq, contactSupport
    /// "Change password" in Account & Security: the forgot password steps with the email filled in.
    case changePassword(email: String)
}

/// The five tabs of the Figma "Menu Bar".
enum AppTab: String, CaseIterable, Sendable {
    case home, chats, speak, progress, account
}

/// Pages Dolingo shows in a web view.
enum WebPage: String, Sendable {
    case privacy, terms
}

/// dolingo://catalog, dolingo://settings, dolingo://premium (paywall in a sheet)
struct DolingoDeepLinkParser: DeepLinkParser {
    func link(from url: URL) -> DeepLink<AppRoute>? {
        guard url.scheme == AppConfig.urlScheme else { return nil }
        switch url.deepLinkSegments().first {
        case "catalog": return DeepLink(route: .catalog)
        case "settings": return DeepLink(route: .settings)
        case "premium": return DeepLink(route: .paywall, presentation: .sheet)
        default: return nil
        }
    }
}
