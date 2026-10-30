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
    @State private var toast: TKToast?
    @Environment(\.locale) private var locale

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
                SignUpScreen(auth: container.auth, onExit: { flow.leaveSignUp() }) { user in
                    flow.didSignIn(user, isNew: true)
                }
            case .login:
                LoginScreen(
                    config: LoginConfig(socialOptions: container.socialProviders.map(Self.socialOption)),
                    auth: container.auth,
                    onSuccess: { user in flow.didSignIn(user, isNew: false) },
                    onSocial: { provider in Task { await flow.signInWithSocial(provider) } },
                    onForgotPassword: { flow.forgotPassword() },
                    onSignUp: { flow.startSignUp() }
                )
            case .resetPassword:
                PasswordResetScreen(auth: container.auth, sendsLink: container.usesFirebase,
                                    onExit: { flow.leaveResetPassword() }) { user in
                    flow.didSignIn(user, isNew: false)
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
        .tkToast($toast)
        .onChange(of: flow.errorKey) { key in
            guard let key else { return }
            toast = TKToast(KitStrings.string(key, locale: locale), style: .error)
            flow.dismissError()
        }
    }

    static func socialOption(_ provider: AuthProvider) -> SocialLoginOption {
        switch provider {
        case .apple: SocialLoginOption(.apple, icon: Image("SocialApple"), accessibilityLabel: "Apple")
        case .facebook: SocialLoginOption(.facebook, icon: Image("SocialFacebook"), accessibilityLabel: "Facebook")
        default: SocialLoginOption(.google, icon: Image("SocialGoogle"), accessibilityLabel: "Google")
        }
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
