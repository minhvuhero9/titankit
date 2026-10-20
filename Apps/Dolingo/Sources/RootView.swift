import SwiftUI

/// Temporary root screen for phase 0. Replaced by Splash/Onboarding from TitanFeatures in phase 3.
struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        VStack(spacing: 12) {
            Text("Dolingo")
                .font(.largeTitle.bold())
            Text("TitanKit \(container.kitVersion)")
                .foregroundStyle(.secondary)
            Text("Môi trường: \(container.config.environment.rawValue)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer(config: .init(environment: .dev, apiBaseURL: URL(string: "https://api-dev.example.com")!)))
}
