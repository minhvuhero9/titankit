import XCTest
@testable import TitanDesignSystem

final class GradientTests: XCTestCase {
    func testMixedBlendsTowardsOther() {
        let mid = RGBA.black.mixed(with: .white, by: 0.5)
        XCTAssertEqual(mid.red, 0.5, accuracy: 0.001)
        XCTAssertEqual(RGBA.black.mixed(with: .white, by: 2), .white)
    }

    func testBaseThemeGradientStartsAtBrand() {
        let theme = Theme.base
        XCTAssertEqual(theme.gradientPrimary.stops.first?.color, theme.colors.actionPrimary.light)
    }

    func testPatchReplacesGradient() {
        let gradient = TKPalette.Gradients.green
        let theme = Theme.base.merged(with: ThemePatch(gradientPrimary: gradient))
        XCTAssertEqual(theme.gradientPrimary, gradient)
    }
}
