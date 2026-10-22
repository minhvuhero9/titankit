import XCTest
import TitanCore
import TitanDesignSystem
import TitanLocalization
@testable import TitanFeatures

final class SettingsScreenTests: XCTestCase {
    func testEverySettingsStringExistsInBothLanguages() {
        let keys = [
            KitStrings.Settings.title, KitStrings.Settings.logout, KitStrings.Settings.logoutConfirm,
            KitStrings.Settings.logoutAction, KitStrings.Settings.appearance, KitStrings.Settings.theme,
            KitStrings.Settings.chooseTheme, KitStrings.Settings.themeSystem, KitStrings.Settings.themeLight,
            KitStrings.Settings.themeDark, KitStrings.Settings.language, KitStrings.Settings.chooseLanguage,
            KitStrings.Settings.helpSupport, KitStrings.Settings.privacy, KitStrings.Settings.terms,
            KitStrings.ok, KitStrings.cancel,
        ]
        for key in keys {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }

    func testEachThemeHasItsOwnTitle() {
        let keys = TKAppearance.allCases.map(AppearanceScreen.titleKey(for:))
        XCTAssertEqual(Set(keys).count, TKAppearance.allCases.count)
        XCTAssertEqual(KitStrings.string(AppearanceScreen.titleKey(for: .dark), locale: Locale(identifier: "vi")), "Tối")
    }

    func testWebPageErrors() {
        XCTAssertEqual(WebPageScreen.titanError(for: URLError(.notConnectedToInternet)), .network(.offline))
        XCTAssertEqual(WebPageScreen.titanError(for: URLError(.timedOut)), .network(.timeout))
        XCTAssertNil(WebPageScreen.titanError(for: URLError(.cancelled)))
        XCTAssertNil(WebPageScreen.titanError(for: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)))
        if case .unknown? = WebPageScreen.titanError(for: URLError(.badURL)) {} else {
            XCTFail("a bad URL should be an unknown error")
        }
    }
}

final class LaunchBlockScreenTests: XCTestCase {
    func testEveryLaunchStringExistsInBothLanguages() {
        let keys = [
            KitStrings.Launch.maintenanceTitle, KitStrings.Launch.maintenanceMessage,
            KitStrings.Launch.updateTitle, KitStrings.Launch.updateMessage, KitStrings.Launch.updateAction,
        ]
        for key in keys {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}
