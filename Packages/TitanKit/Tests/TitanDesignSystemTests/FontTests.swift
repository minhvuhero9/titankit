import UIKit
import XCTest
@testable import TitanDesignSystem

final class FontTests: XCTestCase {
    func testBundledFontsRegisterEveryWeight() {
        TKFonts.registerBundledFonts()
        for family in [TKFonts.urbanist, TKFonts.plusJakartaSans] {
            for weight in [TextStyle.Weight.regular, .medium, .semibold, .bold] {
                let name = TKFonts.postScriptName(family: family, weight: weight)
                XCTAssertNotNil(UIFont(name: name, size: 12), "missing \(name)")
            }
        }
    }

    func testPostScriptNameDropsSpaces() {
        XCTAssertEqual(TKFonts.postScriptName(family: "Plus Jakarta Sans", weight: .semibold), "PlusJakartaSans-SemiBold")
    }

    func testLocalizedFamilyOnlyForListedLanguages() {
        let typography = Typography(
            fontFamily: TKFonts.urbanist,
            localizedFontFamilies: ["vi": TKFonts.plusJakartaSans],
            styles: Typography.base.styles
        )
        XCTAssertEqual(typography.localized(for: Locale(identifier: "vi_VN")).fontFamily, TKFonts.plusJakartaSans)
        XCTAssertEqual(typography.localized(for: Locale(identifier: "en")).fontFamily, TKFonts.urbanist)
    }
}
