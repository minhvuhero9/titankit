import SwiftUI
import TitanAuth
import TitanCore
import TitanDesignSystem
import TitanFeatures
import TitanLocalization
import TitanNavigation

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
                    onGetStarted: { flow.startSignUp() },
                    onSignIn: { flow.finishOnboarding() }
                )
            case .survey:
                SurveyScreen(steps: DolingoSurvey.steps(), answers: flow.surveyAnswers,
                             onExit: { flow.leaveSurvey() }) { answers in
                    flow.finishSurvey(answers)
                }
            case .preparingPlan:
                PreparingScreen(title: Text("plan.preparing.title"), message: Text("plan.preparing.message")) {
                    flow.planIsReady()
                }
            case .planReady:
                SuccessScreen(title: Text("plan.ready.title"), message: Text("plan.ready.message"),
                              actionTitle: Text("plan.ready.action")) {
                    flow.createAccount()
                }
            case .signUp:
                SignUpScreen(auth: container.auth, onExit: { flow.leaveSignUp() }) { _ in
                    flow.didSignIn()
                }
            case .login:
                LoginScreen(
                    config: LoginConfig(socialOptions: [
                        SocialLoginOption(.google, icon: Image("SocialGoogle"), accessibilityLabel: "Google"),
                        SocialLoginOption(.apple, icon: Image("SocialApple"), accessibilityLabel: "Apple"),
                        SocialLoginOption(.facebook, icon: Image("SocialFacebook"), accessibilityLabel: "Facebook"),
                    ]),
                    auth: container.auth,
                    onSuccess: { _ in flow.didSignIn() },
                    onSocial: { provider in Task { await flow.signInWithSocial(provider) } },
                    onForgotPassword: { flow.forgotPassword() },
                    onSignUp: { flow.startSignUp() }
                )
            case .resetPassword:
                PasswordResetScreen(auth: container.auth, onExit: { flow.leaveResetPassword() }) { _ in
                    flow.didSignIn()
                }
            case let .maintenance(message):
                MaintenanceScreen(message: message) { await flow.retryLaunch() }
            case let .forceUpdate(storeURL):
                ForceUpdateScreen(storeURL: storeURL)
            case .home:
                MainTabView(container: container, tabs: container.tabs, flow: flow, activity: container.activity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: flow.stage)
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
