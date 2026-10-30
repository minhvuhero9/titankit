import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanFeatures
import TitanIcons
import TitanLocalization
import TitanNavigation
import TitanPurchase
import TitanStorage

/// Dolingo's rows on the kit's settings screen (Figma "account & settings").
enum DolingoSettings {
    static let preferences = "preferences"
    static let notification = "notification"
    static let security = "security"
    static let billing = "billing"
    static let appearance = "appearance"
    static let help = "help"
    static let invite = "invite"
    static let rateApp = "rateApp"
    static let catalog = "catalog"

    /// Where each row leads; nil for rows that do something else (rate, invite).
    static func route(for id: String) -> AppRoute? {
        switch id {
        case preferences: .preferences
        case notification: .notifications
        case security: .security
        case billing: .billing
        case appearance: .appearance
        case help: .help
        case catalog: .catalog
        default: nil
        }
    }
}

struct DolingoSettingsScreen: View {
    let container: AppContainer
    /// The stack the screen is in: the Account tab's, or Home's when opened from a link.
    let router: Router<AppRoute>
    /// nil when Settings is the root of the Account tab.
    var onBack: (() -> Void)?
    /// Hides the upgrade banner once the user has premium.
    @State private var isPremium = false
    @State private var user: AuthUser?
    @State private var invites = false
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsScreen(
            sections: [
                SettingsSection("app", items: [
                    SettingsItem(DolingoSettings.preferences, title: Text("settings.preferences"), icon: Image(tk: .setting)),
                    SettingsItem(DolingoSettings.notification, title: Text("settings.notification"), icon: Image(tk: .notification)),
                    SettingsItem(DolingoSettings.security, title: Text("settings.security"), icon: Image(tk: .shieldDone)),
                    SettingsItem(DolingoSettings.billing, title: Text("settings.billing"), icon: Image(tk: .wallet)),
                    SettingsItem(DolingoSettings.appearance, title: kit(KitStrings.Settings.appearance), icon: Image(tk: .show)),
                    SettingsItem(DolingoSettings.help, title: Text("settings.help"), icon: Image(tk: .document)),
                    SettingsItem(DolingoSettings.invite, title: Text("settings.invite"), icon: Image(tk: .addUser)),
                    SettingsItem(DolingoSettings.rateApp, title: kit(KitStrings.Settings.rateApp), icon: Image(tk: .star)),
                ] + developerItems),
            ],
            onBack: onBack,
            onSelect: { id in
                if id == DolingoSettings.rateApp { openURL(AppConfig.writeReviewURL) }
                if id == DolingoSettings.invite { invites = true }
                if let route = DolingoSettings.route(for: id) { router.push(route) }
            },
            onLogout: {
                await container.flow.signOut()
                router.popToRoot()
            }
        ) {
            VStack(spacing: Spacing.md) {
                if !isPremium {
                    TKUpgradeBanner(title: Text("settings.upgrade.title"), message: Text("settings.upgrade.message")) {
                        router.present(.paywall)
                    }
                }
                TKOptionCard(
                    title: Text(verbatim: user?.displayName ?? KitStrings.string(KitStrings.Profile.title, locale: locale)),
                    detail: user?.email.map { Text(verbatim: $0) }
                ) {
                    TKAvatar(name: user?.displayName ?? user?.email, size: 48)
                } trailing: {
                    Image(tk: .arrowRight)
                        .resizable().scaledToFit()
                        .frame(width: 20, height: 20)
                } action: {
                    router.push(.profile)
                }
            }
        }
        .sheet(isPresented: $invites) {
            InviteSheet { invites = false }
        }
        .task { user = await container.auth.currentUser() }
        .task {
            for await entitlements in container.purchase.entitlementStream {
                isPremium = entitlements.isPremium
            }
        }
    }

    /// The component catalog, for the team only.
    private var developerItems: [SettingsItem] {
        guard !container.config.environment.isProduction else { return [] }
        return [SettingsItem(DolingoSettings.catalog, title: Text("root.catalog"), icon: Image(tk: .category))]
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
