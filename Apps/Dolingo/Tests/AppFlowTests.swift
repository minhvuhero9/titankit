import XCTest
import TitanAuth
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
