import SwiftUI
import TitanAuth
import TitanCore
import TitanDesignSystem
import TitanFeatures
import TitanLocalization
import TitanNavigation
import TitanNetworking

/// Switches between splash, onboarding, sign-in and the signed-in app.
struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        FlowView(container: container, flow: container.flow)
    }
}

private struct FlowView: View {
    let container: AppContainer
    @ObservedObject var flow: AppFlow

    var body: some View {
        ZStack {
            switch flow.stage {
            case .splash:
                SplashScreen(
                    config: SplashConfig(logo: Image("Logo"), appName: "Dolingo"),
                    prepare: { await flow.prepareLaunch() },
                    onFinish: { flow.finishSplash() }
                )
            case .onboarding:
                OnboardingScreen(
                    config: OnboardingConfig(pages: [
                        OnboardingPage(
                            image: Image("WelcomeIllustration"),
                            title: "onboarding.welcome.title",
                            message: "onboarding.welcome.message"
                        ),
                    ]),
                    onGetStarted: { flow.finishOnboarding() },
                    onSignIn: { flow.finishOnboarding() }
                )
            case .login:
                LoginScreen(
                    config: LoginConfig(socialOptions: [
                        SocialLoginOption(.google, icon: Image("SocialGoogle"), accessibilityLabel: "Google"),
                        SocialLoginOption(.apple, icon: Image("SocialApple"), accessibilityLabel: "Apple"),
                        SocialLoginOption(.facebook, icon: Image("SocialFacebook"), accessibilityLabel: "Facebook"),
                    ]),
                    auth: container.auth,
                    onSuccess: { _ in flow.didSignIn() },
                    onSocial: { provider in Task { await flow.signInWithSocial(provider) } }
                )
            case .home:
                RouterView(router: container.router) {
                    StatusList(container: container, network: container.networkMonitor)
                } destination: { route in
                    container.makeView(for: route)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: flow.stage)
    }
}

/// Temporary home screen until the real Home is built.
private struct StatusList: View {
    let container: AppContainer
    @ObservedObject var network: NetworkMonitor
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

            TKButton("root.settings", style: .light, size: .medium) {
                router.push(.settings)
            }
            .padding(.top, Spacing.lg)
            TKButton("root.catalog", style: .outline, size: .medium) {
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
            .titanTheme(DolingoTheme.theme)
    }
    .environmentObject(container)
}
