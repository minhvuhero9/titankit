import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanFirebaseAuth
import TitanLocalization
import TitanStorage

@main
struct DolingoApp: App {
    @StateObject private var container = AppContainer(config: .current)
    @Preference(DolingoKeys.appearance) private var appearance

    var body: some Scene {
        WindowGroup {
            LocalizedRoot(localization: container.localization) {
                // Inside LocalizedRoot so the theme picks the font for the chosen language.
                RootView()
                    .titanTheme(DolingoTheme.theme)
            }
            .environmentObject(container)
            .environment(\.container, container)
            .environment(\.logger, container.logger)
            .environment(\.imageCache, container.imageCache)
            .tkAppearance(appearance)
            .onOpenURL { url in
                // Google Sign-In comes back through its own URL scheme.
                if GoogleSignInHelper.handle(url) { return }
                _ = container.deepLinks.handle(url)
            }
            // Reads what the user owns and listens for renewals and refunds.
            .task { container.purchase.start() }
        }
    }
}

/// Redraws everything below when the in-app language changes.
struct LocalizedRoot<Content: View>: View {
    @ObservedObject var localization: LocalizationService
    @ViewBuilder var content: Content

    var body: some View {
        content
            .environmentObject(localization)
            .environment(\.locale, localization.locale)
            .id(localization.currentLanguage)
    }
}
