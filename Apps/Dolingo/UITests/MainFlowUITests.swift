import XCTest

/// The main flow on a first launch, on mock services: splash, welcome screen, "I already have an
/// account", sign in as demo@titan.app, Home. In Vietnamese and English, light and dark; each
/// step is attached as a screenshot to look at in the Screenshots workflow's artifact.
@MainActor
final class MainFlowUITests: XCTestCase {
    private struct Strings {
        let language: String, locale: String
        let haveAccount: String, signInTitle: String, signIn: String, homeTab: String
    }

    private let vietnamese = Strings(
        language: "vi", locale: "vi_VN",
        haveAccount: "Tôi đã có tài khoản", signInTitle: "Chào mừng trở lại! 👋",
        signIn: "Đăng nhập", homeTab: "Trang chủ"
    )
    private let english = Strings(
        language: "en", locale: "en_US",
        haveAccount: "I Already Have an Account", signInTitle: "Welcome Back! 👋",
        signIn: "Sign in", homeTab: "Home"
    )

    func testVietnameseLight() { signIn(vietnamese, appearance: "light") }
    func testVietnameseDark() { signIn(vietnamese, appearance: "dark") }
    func testEnglishLight() { signIn(english, appearance: "light") }
    func testEnglishDark() { signIn(english, appearance: "dark") }

    private func signIn(_ strings: Strings, appearance: String) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-freshStart", "-screenshotLanguage", strings.language, "-appearance", appearance,
            "-AppleLanguages", "(\(strings.language))", "-AppleLocale", strings.locale,
        ]
        app.launch()
        let name = "flow-\(strings.language)-\(appearance)"

        let haveAccount = app.buttons[strings.haveAccount]
        XCTAssertTrue(haveAccount.waitForExistence(timeout: 15), "The welcome screen did not show")
        attach(app, "\(name)-1-welcome")
        haveAccount.tap()

        XCTAssertTrue(app.staticTexts[strings.signInTitle].waitForExistence(timeout: 5), "The sign-in screen did not show")
        let email = app.textFields.firstMatch
        email.tap()
        email.typeText("demo@titan.app")
        let password = app.secureTextFields.firstMatch
        password.tap()
        password.typeText("123456")
        attach(app, "\(name)-2-sign-in")
        app.buttons.matching(identifier: strings.signIn).allElementsBoundByIndex.last?.tap()

        XCTAssertTrue(app.staticTexts[strings.homeTab].waitForExistence(timeout: 10), "Home did not show after signing in")
        // Home loads the course before it draws.
        Thread.sleep(forTimeInterval: 2)
        attach(app, "\(name)-3-home")
        app.terminate()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
