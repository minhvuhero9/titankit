import XCTest
import TitanCore
@testable import TitanLocalization

@MainActor
final class LocalizationServiceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "LocalizationServiceTests")
        defaults.removePersistentDomain(forName: "LocalizationServiceTests")
    }

    private func makeService(preferred: [String] = []) -> LocalizationService {
        LocalizationService(supported: ["vi", "en"], defaultLanguage: "vi",
                            preferredLanguages: preferred, defaults: defaults)
    }

    func testUsesDeviceLanguageWhenSupported() {
        XCTAssertEqual(makeService(preferred: ["en-US", "vi-VN"]).currentLanguage, Language("en"))
    }

    func testFallsBackToDefaultForUnsupportedDeviceLanguage() {
        XCTAssertEqual(makeService(preferred: ["fr-FR"]).currentLanguage, Language("vi"))
    }

    func testChoiceIsSavedAndWinsOverDevice() {
        makeService(preferred: ["vi"]).setLanguage(Language("en"))
        XCTAssertEqual(makeService(preferred: ["vi"]).currentLanguage, Language("en"))
    }

    func testUnsupportedLanguageIsIgnored() {
        let service = makeService()
        service.setLanguage(Language("fr"))
        XCTAssertEqual(service.currentLanguage, Language("vi"))
    }

    func testDisplayNameIsInItsOwnLanguage() {
        XCTAssertEqual(Language("en").displayName, "English")
        XCTAssertEqual(Language("vi").displayName, "Tiếng Việt")
    }
}

final class KitStringsTests: XCTestCase {
    func testKitStringsExistInBothLanguages() {
        XCTAssertEqual(KitStrings.string(KitStrings.retry, locale: Locale(identifier: "vi")), "Thử lại")
        XCTAssertEqual(KitStrings.string(KitStrings.retry, locale: Locale(identifier: "en")), "Try again")
    }

    func testMissingKeyReturnsKey() {
        XCTAssertEqual(KitStrings.string("kit.nope", locale: Locale(identifier: "en")), "kit.nope")
    }

    func testEveryErrorHasAMessageInBothLanguages() {
        let errors: [TitanError] = [
            .network(.offline), .network(.timeout), .network(.server(statusCode: 500)),
            .unauthorized, .decoding("x"), .notFound, .storage("x"), .cancelled, .unknown("x"),
        ]
        for error in errors {
            for code in ["vi", "en"] {
                let text = KitStrings.string(error.messageKey, locale: Locale(identifier: code))
                XCTAssertNotEqual(text, error.messageKey, "\(error) \(code)")
            }
        }
        XCTAssertEqual(KitStrings.string(TitanError.notFound.messageKey, locale: Locale(identifier: "vi")),
                       TitanError.notFound.userMessage)
    }
}

final class TKFormatterTests: XCTestCase {
    func testCurrencyFollowsLanguage() {
        let vi = TKFormatter(locale: Locale(identifier: "vi_VN")).currency(1000, code: "VND")
        let en = TKFormatter(locale: Locale(identifier: "en_US")).currency(1000, code: "VND")
        XCTAssertTrue(vi.contains("1.000"), vi)
        XCTAssertTrue(vi.contains("₫"), vi)
        XCTAssertTrue(en.contains("1,000"), en)
    }

    func testNumberAndPercent() {
        let en = TKFormatter(locale: Locale(identifier: "en_US"))
        XCTAssertEqual(en.number(1234.5, fractionDigits: 1), "1,234.5")
        XCTAssertEqual(en.percent(0.25), "25%")
        let vi = TKFormatter(locale: Locale(identifier: "vi_VN"))
        XCTAssertEqual(vi.number(1234.5, fractionDigits: 1), "1.234,5")
    }
}
