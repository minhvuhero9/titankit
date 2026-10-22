import SwiftUI
import TitanDesignSystem
import TitanFeatures
import TitanIcons
import TitanLocalization
import TitanStorage

/// Dolingo's rows on the kit's settings screen. More rows arrive with their screens
/// (profile, notifications, subscription...).
enum DolingoSettings {
    static let profile = "profile"
    static let appearance = "appearance"
    static let rateApp = "rateApp"
    static let privacy = "privacy"
    static let terms = "terms"
    static let catalog = "catalog"

    /// Where each row leads.
    static func route(for id: String) -> AppRoute? {
        switch id {
        case profile: .profile
        case appearance: .appearance
        case privacy: .webPage(.privacy)
        case terms: .webPage(.terms)
        case catalog: .catalog
        default: nil
        }
    }
}

struct DolingoSettingsScreen: View {
    let container: AppContainer
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsScreen(
            sections: [
                SettingsSection("app", items: [
                    SettingsItem(DolingoSettings.profile, title: kit(KitStrings.Profile.title), icon: Image(tk: .profile)),
                    SettingsItem(DolingoSettings.appearance, title: kit(KitStrings.Settings.appearance), icon: Image(tk: .show)),
                    SettingsItem(DolingoSettings.rateApp, title: kit(KitStrings.Settings.rateApp), icon: Image(tk: .star)),
                    SettingsItem(DolingoSettings.catalog, title: Text("root.catalog"), icon: Image(tk: .category)),
                ]),
                SettingsSection("legal", items: [
                    SettingsItem(DolingoSettings.privacy, title: kit(KitStrings.Settings.privacy), icon: Image(tk: .shieldDone)),
                    SettingsItem(DolingoSettings.terms, title: kit(KitStrings.Settings.terms), icon: Image(tk: .document)),
                ]),
            ],
            onBack: { container.router.pop() },
            onSelect: { id in
                if id == DolingoSettings.rateApp { openURL(AppConfig.writeReviewURL) }
                if let route = DolingoSettings.route(for: id) { container.router.push(route) }
            },
            onLogout: {
                await container.flow.signOut()
                container.router.popToRoot()
            }
        )
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}

struct DolingoAppearanceScreen: View {
    let localization: LocalizationService
    let onBack: () -> Void
    @Preference(DolingoKeys.appearance) private var appearance

    var body: some View {
        AppearanceScreen(appearance: $appearance, localization: localization, onBack: onBack)
    }
}

extension WebPage {
    var titleKey: String {
        switch self {
        case .privacy: KitStrings.Settings.privacy
        case .terms: KitStrings.Settings.terms
        }
    }

    var url: URL {
        switch self {
        case .privacy: AppConfig.privacyURL
        case .terms: AppConfig.termsURL
        }
    }
}

struct DolingoWebPage: View {
    let page: WebPage
    let onBack: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        WebPageScreen(title: Text.kit(page.titleKey, locale: locale), url: page.url, onBack: onBack)
    }
}
