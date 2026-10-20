import XCTest
import TitanAuth
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
}
