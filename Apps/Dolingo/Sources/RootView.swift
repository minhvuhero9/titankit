import SwiftUI
import TitanCore
import TitanNetworking

/// Temporary root screen. Replaced by Splash/Onboarding from TitanFeatures in phase 3.
struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        StatusList(container: container, network: container.networkMonitor)
    }
}

private struct StatusList: View {
    let container: AppContainer
    @ObservedObject var network: NetworkMonitor

    var body: some View {
        VStack(spacing: 12) {
            Text("Dolingo")
                .font(.largeTitle.bold())
            Text("TitanKit \(container.kitVersion)")
                .foregroundStyle(.secondary)
            Text("Môi trường: \(container.config.environment.rawValue)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Label(network.isOnline ? "Đang có mạng" : "Mất mạng",
                  systemImage: network.isOnline ? "wifi" : "wifi.slash")
                .font(.footnote)
                .foregroundStyle(network.isOnline ? Color.secondary : Color.red)
        }
        .padding()
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer.preview())
}
