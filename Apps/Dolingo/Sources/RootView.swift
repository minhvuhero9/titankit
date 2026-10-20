import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanLocalization
import TitanNavigation
import TitanNetworking

/// Temporary root screen. Replaced by Splash/Onboarding from TitanFeatures in phase 3b.
struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        RouterView(router: container.router) {
            StatusList(container: container, network: container.networkMonitor)
        } destination: { route in
            container.makeView(for: route)
        }
    }
}

private struct StatusList: View {
    let container: AppContainer
    @ObservedObject var network: NetworkMonitor
    @EnvironmentObject private var localization: LocalizationService
    @EnvironmentObject private var router: Router<AppRoute>
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("Dolingo")
                .tkTextStyle(.display)
                .foregroundStyle(theme.colors.actionPrimary.color)
            Text("TitanKit \(container.kitVersion)")
                .tkTextStyle(.body)
                .foregroundStyle(theme.colors.textSecondary.color)
            Text("root.environment \(container.config.environment.rawValue)")
                .tkTextStyle(.callout)
                .foregroundStyle(theme.colors.textSecondary.color)
            Label(network.isOnline ? "root.network.online" : "root.network.offline",
                  systemImage: network.isOnline ? "wifi" : "wifi.slash")
                .tkTextStyle(.callout)
                .foregroundStyle(network.isOnline ? theme.colors.feedbackSuccess.color : theme.colors.feedbackError.color)

            Picker("root.language", selection: Binding(
                get: { localization.currentLanguage },
                set: { localization.setLanguage($0) }
            )) {
                ForEach(localization.supportedLanguages) { language in
                    Text(verbatim: language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, Spacing.lg)

            TKButton("root.catalog", style: .light, size: .medium) {
                router.push(.catalog)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color)
    }
}

#Preview {
    let container = AppContainer.preview()
    return LocalizedRoot(localization: container.localization) {
        RootView()
    }
    .environmentObject(container)
    .titanTheme(DolingoTheme.theme)
}
