import XCTest
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
}
