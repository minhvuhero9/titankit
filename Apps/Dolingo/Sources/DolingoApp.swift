import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanLocalization

@main
struct DolingoApp: App {
    @StateObject private var container = AppContainer(config: .current)

    var body: some Scene {
        WindowGroup {
            LocalizedRoot(localization: container.localization) {
                RootView()
            }
            .environmentObject(container)
            .environment(\.container, container)
            .environment(\.logger, container.logger)
            .environment(\.imageCache, container.imageCache)
            .titanTheme(DolingoTheme.theme)
            .onOpenURL { _ = container.deepLinks.handle($0) }
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
