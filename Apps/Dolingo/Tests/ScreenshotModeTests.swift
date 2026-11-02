import XCTest
import TitanAuth
import TitanCore
@testable import Dolingo

@MainActor
final class ScreenshotModeTests: XCTestCase {
    func testReadsTheScreenAndLanguageFromTheLaunchArguments() {
        let arguments = ["Dolingo", "-screenshots", "tutor", "-screenshotLanguage", "en"]
        XCTAssertEqual(ScreenshotMode.screen(in: arguments), .tutor)
        XCTAssertEqual(ScreenshotMode.language(in: arguments), "en")
        XCTAssertNil(ScreenshotMode.screen(in: ["Dolingo"]))
        XCTAssertNil(ScreenshotMode.screen(in: ["Dolingo", "-screenshots"]))
        XCTAssertEqual(ScreenshotMode.language(in: ["-screenshotLanguage", "fr"]), AppConfig.defaultLanguage)
    }

    func testStartsSignedInWithProgressOnTheChosenScreen() async {
        let container = ScreenshotMode.container(for: .tutor, language: "en")
        XCTAssertEqual(container.tabs.selected, .chats)
        XCTAssertEqual(container.localization.currentLanguage.code, "en")
        let user = await container.auth.currentUser()
        XCTAssertEqual(user?.displayName, "Minh")
        XCTAssertEqual(container.learning.progress.completedLessons.count, 3)
        XCTAssertEqual(container.tutorChat.messages.first?.text, "How do I order a coffee politely?")
    }

    func testSeedsAWeekStreakInItsOwnDefaults() {
        let container = ScreenshotMode.container(for: .progress, language: "vi")
        XCTAssertEqual(container.tabs.selected, .progress)
        XCTAssertEqual(container.activity.currentStreak, 7)
        // Written to its own suite, so the app's real data is never touched.
        let suite = UserDefaults(suiteName: ScreenshotMode.suiteName)
        XCTAssertNotNil(suite?.object(forKey: DolingoKeys.activity.name))
    }

    func testFreshStartOpensOnTheWelcomeScreenSignedOut() async {
        XCTAssertTrue(ScreenshotMode.isFreshStart(in: ["Dolingo", "-freshStart"]))
        XCTAssertFalse(ScreenshotMode.isFreshStart(in: ["Dolingo"]))
        XCTAssertEqual(ScreenshotMode.appearance(in: ["-appearance", "dark"]), .dark)
        XCTAssertNil(ScreenshotMode.appearance(in: ["-appearance", "sepia"]))

        let container = AppContainer.launch(arguments: ["Dolingo", "-freshStart", "-screenshotLanguage", "en"])
        XCTAssertEqual(container.localization.currentLanguage.code, "en")
        let user = await container.auth.currentUser()
        XCTAssertNil(user)
        await container.flow.prepareLaunch()
        container.flow.finishSplash()
        XCTAssertEqual(container.flow.stage, .onboarding)
        // The account MainFlowUITests signs in with.
        let signedIn = try? await container.auth.signIn(.email(email: "demo@titan.app", password: "123456"))
        XCTAssertNotNil(signedIn)
    }
}
