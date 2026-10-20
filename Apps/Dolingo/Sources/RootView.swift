import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanNetworking

/// Temporary root screen. Replaced by Splash/Onboarding from TitanFeatures in phase 3.
struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        NavigationStack {
            StatusList(container: container, network: container.networkMonitor)
        }
    }
}

private struct StatusList: View {
    let container: AppContainer
    @ObservedObject var network: NetworkMonitor
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("Dolingo")
                .tkTextStyle(.display)
                .foregroundStyle(theme.colors.actionPrimary.color)
            Text("TitanKit \(container.kitVersion)")
                .tkTextStyle(.body)
                .foregroundStyle(theme.colors.textSecondary.color)
            Text("Môi trường: \(container.config.environment.rawValue)")
                .tkTextStyle(.callout)
                .foregroundStyle(theme.colors.textSecondary.color)
            Label(network.isOnline ? "Đang có mạng" : "Mất mạng",
                  systemImage: network.isOnline ? "wifi" : "wifi.slash")
                .tkTextStyle(.callout)
                .foregroundStyle(network.isOnline ? theme.colors.feedbackSuccess.color : theme.colors.feedbackError.color)
            NavigationLink {
                TKCatalogView()
            } label: {
                Text("Xem bộ component")
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.actionPrimary.color)
            }
            .padding(.top, Spacing.lg)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color)
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer.preview())
        .titanTheme(DolingoTheme.theme)
}
