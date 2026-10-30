import XCTest
import TitanAnalytics
import TitanAuth
import TitanCore
import TitanFeatures
import TitanRemoteConfig
import TitanStorage
@testable import Dolingo

@MainActor
final class AppFlowTests: XCTestCase {
    /// Fresh, empty preferences for each test.
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "AppFlowTests")!
        defaults.removePersistentDomain(forName: "AppFlowTests")
        return Preferences(defaults: defaults)
    }

    func testFirstLaunchShowsOnboarding() async {
        let preferences = makePreferences()
        let flow = AppFlow(auth: MockAuthService(), preferences: preferences)
        XCTAssertEqual(flow.stage, .splash)
        await flow.prepareLaunch()
        flow.finishSplash()
        XCTAssertEqual(flow.stage, .onboarding)
    }

    func testAfterOnboardingGoesStraightToLogin() async {
        let preferences = makePreferences()
        let flow = AppFlow(auth: MockAuthService(), preferences: preferences)
        flow.finishOnboarding()
        XCTAssertEqual(flow.stage, .login)

        let relaunch = AppFlow(auth: MockAuthService(), preferences: preferences)
        await relaunch.prepareLaunch()
        relaunch.finishSplash()
        XCTAssertEqual(relaunch.stage, .login)
    }

    func testSignUpGoesThroughTheQuestionsThePlanAndTheAccount() async {
        let preferences = makePreferences()
        let flow = AppFlow(auth: MockAuthService(), preferences: preferences)
        flow.startSignUp()
        XCTAssertEqual(flow.stage, .survey)
        flow.leaveSurvey()
        XCTAssertEqual(flow.stage, .onboarding)

        flow.startSignUp()
        let answers: [String: SurveyAnswer] = [DolingoSurvey.Step.level: .options(["beginner"])]
        flow.finishSurvey(answers)
        XCTAssertEqual(flow.stage, .preparingPlan)
        XCTAssertEqual(flow.surveyAnswers, answers)
        flow.planIsReady()
        XCTAssertEqual(flow.stage, .planReady)
        flow.createAccount()
        XCTAssertEqual(flow.stage, .signUp)
        flow.leaveSignUp()
        XCTAssertEqual(flow.stage, .planReady)
        flow.createAccount()
        flow.didSignIn()
        XCTAssertEqual(flow.stage, .home)

        // Someone who started signing up lands on sign-in next time, with the answers kept.
        let relaunch = AppFlow(auth: MockAuthService(), preferences: preferences)
        await relaunch.prepareLaunch()
        relaunch.finishSplash()
        XCTAssertEqual(relaunch.stage, .login)
        XCTAssertEqual(relaunch.surveyAnswers, answers)
    }

    func testSignedInUserSkipsToHome() async {
        let preferences = makePreferences()
        let user = AuthUser(id: "1", email: "a@b.co", provider: .email)
        let flow = AppFlow(auth: MockAuthService(signedIn: user), preferences: preferences)
        await flow.prepareLaunch()
        flow.finishSplash()
        XCTAssertEqual(flow.stage, .home)
        await flow.signOut()
        XCTAssertEqual(flow.stage, .login)
    }

    func testSocialButtonsSignInAsGuestForNow() async {
        let auth = MockAuthService()
        let flow = AppFlow(auth: auth, preferences: makePreferences())
        await flow.signInWithSocial(.google)
        XCTAssertEqual(flow.stage, .home)
        let user = await auth.currentUser()
        XCTAssertEqual(user?.isAnonymous, true)
    }

    func testSocialButtonsUseTheProvidersCredential() async {
        let auth = MockAuthService()
        let analytics = SpyAnalyticsService()
        var asked: [AuthProvider] = []
        let flow = AppFlow(auth: auth, preferences: makePreferences(), analytics: analytics) { provider in
            asked.append(provider)
            return .google(idToken: "id", accessToken: "access")
        }
        await flow.signInWithSocial(.google)
        XCTAssertEqual(asked, [.google])
        XCTAssertEqual(flow.stage, .home)
        let user = await auth.currentUser()
        XCTAssertEqual(user?.provider, .google)
        XCTAssertEqual(analytics.events, [.login(method: "google")])
        XCTAssertEqual(analytics.userId, user?.id)
    }

    func testClosingTheSocialSheetStaysQuietly() async {
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences()) { (_: AuthProvider) async throws(TitanError) -> SignInMethod in
            throw .cancelled
        }
        flow.finishOnboarding()
        await flow.signInWithSocial(.apple)
        XCTAssertEqual(flow.stage, .login)
        XCTAssertNil(flow.errorKey)
    }

    func testAFailedSocialSignInIsShown() async {
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences()) { (_: AuthProvider) async throws(TitanError) -> SignInMethod in
            throw .network(.offline)
        }
        flow.finishOnboarding()
        await flow.signInWithSocial(.apple)
        XCTAssertEqual(flow.stage, .login)
        XCTAssertEqual(flow.errorKey, "login.social.failed")
    }

    func testSignUpIsTrackedAsNew() {
        let analytics = SpyAnalyticsService()
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences(), analytics: analytics)
        flow.didSignIn(AuthUser(id: "7", email: "a@b.co", provider: .email), isNew: true)
        XCTAssertEqual(flow.stage, .home)
        XCTAssertEqual(analytics.events, [.signUp(method: "email")])
    }

    func testFirebaseFilePerEnvironment() {
        XCTAssertEqual(AppContainer.firebasePlistName(.dev), "GoogleService-Info-Dev")
        XCTAssertEqual(AppContainer.firebasePlistName(.staging), "GoogleService-Info-Staging")
        XCTAssertEqual(AppContainer.firebasePlistName(.prod), "GoogleService-Info-Prod")
        XCTAssertTrue(AppContainer.forcesBlockingScreen(["app", "-maintenance"]))
        XCTAssertFalse(AppContainer.forcesBlockingScreen(["app"]))
    }

    func testDataSharingChoicesReachTheServices() {
        let preferences = makePreferences()
        let spy = SpyAnalyticsService()
        let store = DataSharingStore(preferences: preferences, analytics: spy, crash: spy)
        XCTAssertTrue(spy.isCollectionEnabled)
        store.settings.analytics = false
        XCTAssertFalse(spy.isCollectionEnabled)
        let reopened = DataSharingStore(preferences: preferences, analytics: SpyAnalyticsService(), crash: SpyAnalyticsService())
        XCTAssertFalse(reopened.settings.analytics)
        XCTAssertTrue(reopened.settings.crashReports)
    }

    func testMaintenanceBlocksTheAppUntilItEnds() async {
        let config = MockRemoteConfig(values: ["maintenance_enabled": .bool(true)])
        let checker = LaunchChecker(config: config, appVersion: "1.0.0", storeURL: AppConfig.appStoreURL)
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences(), launchChecker: checker)
        await flow.prepareLaunch()
        flow.finishSplash()
        XCTAssertEqual(flow.stage, .maintenance(message: ""))

        await flow.retryLaunch()
        XCTAssertEqual(flow.stage, .maintenance(message: ""))

        config.set(.bool(false), for: "maintenance_enabled")
        await flow.retryLaunch()
        XCTAssertEqual(flow.stage, .onboarding)
    }

    func testOldVersionMustUpdate() async {
        let config = MockRemoteConfig(values: ["minimum_version": .string("2.0.0")])
        let checker = LaunchChecker(config: config, appVersion: "1.0.0", storeURL: AppConfig.appStoreURL)
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences(), launchChecker: checker)
        await flow.prepareLaunch()
        flow.finishSplash()
        XCTAssertEqual(flow.stage, .forceUpdate(storeURL: AppConfig.appStoreURL))
    }

    func testLaunchArgumentsTurnOnTheBlockingScreens() {
        let normal = AppContainer.launchArgumentConfig([])
        XCTAssertFalse(normal.value(for: .maintenanceEnabled))
        let maintenance = AppContainer.launchArgumentConfig(["-maintenance"])
        XCTAssertTrue(maintenance.value(for: .maintenanceEnabled))
        let update = AppContainer.launchArgumentConfig(["-forceUpdate"])
        XCTAssertEqual(update.value(for: .minimumVersion), "999.0.0")
    }

    func testForgotPasswordOpensTheResetAndComesBack() {
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences())
        flow.finishOnboarding()
        flow.forgotPassword()
        XCTAssertEqual(flow.stage, .resetPassword)
        flow.leaveResetPassword()
        XCTAssertEqual(flow.stage, .login)
        flow.forgotPassword()
        flow.didSignIn()
        XCTAssertEqual(flow.stage, .home)
    }

    func testDeletedAccountGoesBackToSignIn() async {
        let user = AuthUser(id: "1", email: "a@b.co", provider: .email)
        let flow = AppFlow(auth: MockAuthService(signedIn: user), preferences: makePreferences())
        await flow.prepareLaunch()
        flow.finishSplash()
        flow.didDeleteAccount()
        XCTAssertEqual(flow.stage, .login)
    }

    func testAsksForReviewAfterLaunchesAndGoodMomentsAndOnlyOnce() async {
        let preferences = makePreferences()
        let flow = AppFlow(auth: MockAuthService(), preferences: preferences, appVersion: "1.0.0")
        await flow.prepareLaunch()
        XCTAssertEqual(preferences.value(DolingoKeys.ratePrompt).launches, 1)
        XCTAssertFalse(flow.shouldAskForReview)

        preferences.set(RatePromptState(firstLaunch: Date().addingTimeInterval(-10 * 86_400), launches: 2, significantEvents: 2), for: DolingoKeys.ratePrompt)
        await flow.prepareLaunch()
        XCTAssertFalse(flow.shouldAskForReview)
        flow.recordSignificantEvent()
        XCTAssertTrue(flow.shouldAskForReview)

        flow.didAskForReview()
        XCTAssertFalse(flow.shouldAskForReview)
        XCTAssertEqual(preferences.value(DolingoKeys.ratePrompt).lastPromptVersion, "1.0.0")
    }
}
