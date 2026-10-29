import CoreGraphics
import XCTest
@testable import TitanDesignSystem

final class SelectionTests: XCTestCase {
    private let colors = Theme.base.colors

    func testSwitchUsesBrandWhenOn() {
        for variant in [TKSwitchToggleStyle.Variant.standard, .line] {
            XCTAssertEqual(TKSwitchColors.resolve(variant, isOn: true, colors: colors).track, colors.actionPrimary)
            XCTAssertEqual(TKSwitchColors.resolve(variant, isOn: false, colors: colors).track, colors.border)
        }
        XCTAssertEqual(TKSwitchColors.resolve(.line, isOn: true, colors: colors).knobBorder, colors.actionPrimary)
        XCTAssertNil(TKSwitchColors.resolve(.standard, isOn: true, colors: colors).knobBorder)
    }

    func testChipStyles() {
        XCTAssertEqual(TKChipColors.resolve(.filled, colors: colors).background, colors.actionPrimary)
        XCTAssertNil(TKChipColors.resolve(.outline, colors: colors).background)
        XCTAssertEqual(TKChipColors.resolve(.outline, colors: colors).border, colors.actionPrimary)
        XCTAssertEqual(TKChipColors.resolve(.neutral, colors: colors).border, colors.border)
    }

    func testChipSizesMatchFigma() {
        XCTAssertEqual(TKChip.Size.allCases.map(\.height), [34, 42, 49])
    }

    func testTagToneAndStyle() {
        let solid = TKTagColors.resolve(tone: .error, style: .solid, colors: colors)
        XCTAssertEqual(solid.background, colors.feedbackError)
        XCTAssertEqual(solid.foreground, AdaptiveColor(.white))

        let soft = TKTagColors.resolve(tone: .success, style: .soft, colors: colors)
        XCTAssertEqual(soft.foreground, colors.feedbackSuccess)
        XCTAssertNotEqual(soft.background?.light, colors.feedbackSuccess.light)

        XCTAssertTrue(TKTagColors.resolve(tone: .info, style: .outline, colors: colors).hasBorder)
        XCTAssertNil(TKTagColors.resolve(tone: .warning, style: .plain, colors: colors).background)
    }

    func testMultipleSelectionToggles() {
        var set: Set<Int> = [1]
        set = TKSelection.toggling(2, in: set)
        XCTAssertEqual(set, [1, 2])
        set = TKSelection.toggling(1, in: set)
        XCTAssertEqual(set, [2])
    }
}

final class TKFlowLayoutTests: XCTestCase {
    private let chip = CGSize(width: 100, height: 40)

    func testWrapsWhenTheLineIsFull() {
        let result = TKFlowLayout.arrange([chip, chip, chip], width: 250, spacing: 10, lineSpacing: 12)
        XCTAssertEqual(result.origins, [CGPoint(x: 0, y: 0), CGPoint(x: 110, y: 0), CGPoint(x: 0, y: 52)])
        XCTAssertEqual(result.size, CGSize(width: 210, height: 92))
    }

    func testTooWideViewGetsItsOwnLine() {
        let wide = CGSize(width: 400, height: 40)
        let result = TKFlowLayout.arrange([wide, chip], width: 300, spacing: 10, lineSpacing: 12)
        XCTAssertEqual(result.origins, [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 52)])
    }

    func testNothingTakesNoSpace() {
        XCTAssertEqual(TKFlowLayout.arrange([], width: 300, spacing: 10, lineSpacing: 12).size, .zero)
    }
}
