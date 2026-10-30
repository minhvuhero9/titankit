import XCTest

/// Takes the App Store screenshots in Vietnamese and English. Run with Tools/screenshots.sh,
/// which picks the simulator and copies the images out of the test results.
@MainActor
final class AppStoreScreenshots: XCTestCase {
    /// In App Store order. The names match `ScreenshotMode.Screen` in the app.
    private let screens = ["home", "lesson", "chats", "tutor", "speak", "progress", "paywall"]

    func testVietnamese() {
        capture(language: "vi", locale: "vi_VN")
    }

    func testEnglish() {
        capture(language: "en", locale: "en_US")
    }

    private func capture(language: String, locale: String) {
        continueAfterFailure = false
        for (index, screen) in screens.enumerated() {
            let app = XCUIApplication()
            app.launchArguments = [
                "-screenshots", screen, "-screenshotLanguage", language,
                "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
            ]
            app.launch()
            // The splash, then the screen and its sheet animating in.
            Thread.sleep(forTimeInterval: 5)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "\(language)-\(index + 1)-\(screen)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }
}
