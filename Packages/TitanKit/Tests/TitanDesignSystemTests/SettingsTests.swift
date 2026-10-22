import XCTest
import TitanLocalization
@testable import TitanDesignSystem

final class SettingsTests: XCTestCase {
    func testOutlinedCardBorderThickensWhenSelected() {
        XCTAssertEqual(TKOutlinedCardMetrics.borderWidth(isSelected: false), 2)
        XCTAssertEqual(TKOutlinedCardMetrics.borderWidth(isSelected: true), 3)
        // 2 pt border plus 3 pt edge makes Figma's 5 pt bottom border.
        XCTAssertEqual(TKOutlinedCardMetrics.borderWidth(isSelected: false) + TKOutlinedCardMetrics.bottomEdge, 5)
    }

    func testCurrentPlanStringExistsInBothLanguages() {
        XCTAssertEqual(KitStrings.string(KitStrings.currentPlan, locale: Locale(identifier: "vi")), "Gói hiện tại của bạn")
        XCTAssertEqual(KitStrings.string(KitStrings.currentPlan, locale: Locale(identifier: "en")), "Your current plan")
    }
}
