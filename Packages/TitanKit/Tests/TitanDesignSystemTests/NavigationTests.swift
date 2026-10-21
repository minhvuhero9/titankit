import XCTest
import TitanLocalization
@testable import TitanDesignSystem

final class NavigationTests: XCTestCase {
    func testProgressIsClamped() {
        XCTAssertEqual(TKProgressBar.clamped(-0.5), 0)
        XCTAssertEqual(TKProgressBar.clamped(0.4), 0.4)
        XCTAssertEqual(TKProgressBar.clamped(3), 1)
        XCTAssertEqual(TKProgressBar.clamped(.nan), 0)
    }

    func testSearchStringsExistInBothLanguages() {
        for key in [KitStrings.search, KitStrings.clear] {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}
