import Foundation
import TitanAuth
import TitanDesignSystem
import TitanFeatures
import TitanRemoteConfig
import TitanStorage

enum DolingoKeys {
    static let hasSeenOnboarding = PreferenceKey("dolingo.hasSeenOnboarding", default: false)
    /// Light, dark or follow the device, picked on the App Appearance screen.
    static let appearance = PreferenceKey<TKAppearance>("dolingo.appearance", default: .system)
    /// Launches and good moments counted for the App Store rating prompt.
    static let ratePrompt = PreferenceKey("dolingo.ratePrompt", default: RatePromptState())
    /// Sign-up questionnaire answers by step id (`DolingoSurvey.Step`).
    static let surveyAnswers = PreferenceKey<[String: SurveyAnswer]>("dolingo.surveyAnswers", default: [:])
    /// Courses added, the active one and finished lessons.
    static let learningProgress = PreferenceKey("dolingo.learningProgress", default: LearningProgress())
    /// Phrases bookmarked on the Speak tab.
    static let savedPhrases = PreferenceKey<[Phrase]>("dolingo.savedPhrases", default: [])
    /// Counts, streak days and badges for My Progress.
    static let activity = PreferenceKey("dolingo.activity", default: ActivityStats())
    /// The daily study reminder.
    static let reminder = PreferenceKey("dolingo.reminder", default: ReminderSettings())
}

/// Which part of the app is showing: splash, onboarding, the sign-up steps, sign-in,
/// the signed-in app, or a screen that blocks the app (maintenance, forced update).
@MainActor
final class AppFlow: ObservableObject {
    enum Stage: Equatable {
        case splash, onboarding, login, home
        /// Sign-up: the questionnaire, the plan being prepared, the plan ready, the account form.
        case survey, preparingPlan, planReady, signUp
        /// "Forgot password?" on the sign-in screen: email, code, new password, done.
        case resetPassword
        case maintenance(message: String)
        case forceUpdate(storeURL: URL)
    }

    @Published private(set) var stage: Stage = .splash
    private var stageAfterSplash: Stage = .onboarding

    private let auth: any AuthService
    private let preferences: Preferences
    private let launchChecker: LaunchChecker?
    private let appVersion: String
    /// Asks only after good moments, never on the first launches. Lessons (phase 5) call
    /// `recordSignificantEvent`, so the prompt cannot show before then.
    private let ratePolicy = RatePromptPolicy()

    /// - Parameter launchChecker: nil skips the maintenance and update check.
    init(auth: any AuthService, preferences: Preferences, launchChecker: LaunchChecker? = nil, appVersion: String = "0.0.0") {
        self.auth = auth
        self.preferences = preferences
        self.launchChecker = launchChecker
        self.appVersion = appVersion
    }

    /// Runs while the splash is up.
    func prepareLaunch() async {
        updateRatePrompt { $0.recordLaunch() }
        if let blocked = await blockingStage() {
            stageAfterSplash = blocked
            return
        }
        await chooseFirstScreen()
    }

    /// "Thử lại" on the maintenance screen: checks again and lets the user in once it's over.
    func retryLaunch() async {
        if let blocked = await blockingStage() {
            stage = blocked
            return
        }
        await chooseFirstScreen()
        stage = stageAfterSplash
    }

    private func blockingStage() async -> Stage? {
        let status = await launchChecker?.check() ?? .ok
        switch status {
        case .ok: return nil
        case let .maintenance(message): return .maintenance(message: message)
        case let .forceUpdate(storeURL): return .forceUpdate(storeURL: storeURL)
        }
    }

    private func chooseFirstScreen() async {
        if await auth.currentUser() != nil {
            stageAfterSplash = .home
        } else if preferences.value(DolingoKeys.hasSeenOnboarding) {
            stageAfterSplash = .login
        } else {
            stageAfterSplash = .onboarding
        }
    }

    func finishSplash() {
        stage = stageAfterSplash
    }

    /// "I already have an account" on the welcome screen.
    func finishOnboarding() {
        preferences.set(true, for: DolingoKeys.hasSeenOnboarding)
        stage = .login
    }

    /// "Get started" on the welcome screen, or "Sign up" on the sign-in screen.
    func startSignUp() {
        preferences.set(true, for: DolingoKeys.hasSeenOnboarding)
        stage = .survey
    }

    /// Back on the first question: the welcome screen.
    func leaveSurvey() {
        stage = .onboarding
    }

    var surveyAnswers: [String: SurveyAnswer] {
        preferences.value(DolingoKeys.surveyAnswers)
    }

    func finishSurvey(_ answers: [String: SurveyAnswer]) {
        preferences.set(answers, for: DolingoKeys.surveyAnswers)
        stage = .preparingPlan
    }

    func planIsReady() {
        stage = .planReady
    }

    /// "Create an Account" on the plan ready screen.
    func createAccount() {
        stage = .signUp
    }

    /// Back on the first sign-up field.
    func leaveSignUp() {
        stage = .planReady
    }

    /// "Forgot password?" on the sign-in screen.
    func forgotPassword() {
        stage = .resetPassword
    }

    /// Back on the first reset step, or the new password must be typed on the sign-in screen.
    func leaveResetPassword() {
        stage = .login
    }

    func didSignIn() {
        stage = .home
    }

    /// Apple, Google and Facebook sign-in arrive with the Firebase adapter (phase 4).
    /// Until then their buttons sign in as a guest so the flow can be tried end to end.
    func signInWithSocial(_ provider: AuthProvider) async {
        guard (try? await auth.signIn(.anonymous)) != nil else { return }
        didSignIn()
    }

    /// The account is already gone on the backend; back to sign-in.
    func didDeleteAccount() {
        stage = .login
    }

    /// Read by the home screen, which shows the system rating prompt when this is true.
    var shouldAskForReview: Bool {
        preferences.value(DolingoKeys.ratePrompt).isDue(ratePolicy, version: appVersion)
    }

    func didAskForReview() {
        updateRatePrompt { $0.recordPrompt(version: appVersion) }
    }

    /// Called when something goes well, e.g. a finished lesson.
    func recordSignificantEvent() {
        updateRatePrompt { $0.recordSignificantEvent() }
    }

    private func updateRatePrompt(_ change: (inout RatePromptState) -> Void) {
        var state = preferences.value(DolingoKeys.ratePrompt)
        change(&state)
        preferences.set(state, for: DolingoKeys.ratePrompt)
    }

    func signOut() async {
        try? await auth.signOut()
        stage = .login
    }
}
