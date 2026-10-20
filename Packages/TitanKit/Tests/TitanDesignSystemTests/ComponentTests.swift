import XCTest
@testable import TitanDesignSystem

final class TKButtonColorsTests: XCTestCase {
    private let colors = Theme.base.colors

    func testPrimaryUsesActionColours() {
        let result = TKButtonColors.resolve(.primary, colors: colors, isEnabled: true)
        XCTAssertEqual(result.background, colors.actionPrimary)
        XCTAssertEqual(result.foreground, colors.actionOnPrimary)
        XCTAssertNil(result.border)
        XCTAssertNil(result.edge)
    }

    func testOutlineHasBorderButNoFill() {
        let result = TKButtonColors.resolve(.outline, colors: colors, isEnabled: true)
        XCTAssertNil(result.background)
        XCTAssertEqual(result.border, colors.actionPrimary)
    }

    func testOnlyThreeDHasAnEdge() {
        for style in TKButton.Style.allCases {
            let result = TKButtonColors.resolve(style, colors: colors, isEnabled: true)
            XCTAssertEqual(result.edge != nil, style == .threeD, "\(style)")
        }
        XCTAssertEqual(TKButtonColors.resolve(.threeD, colors: colors, isEnabled: true).edge, colors.actionPrimaryPressed)
    }

    func testOnlyElevatedHasAShadow() {
        for style in TKButton.Style.allCases {
            let result = TKButtonColors.resolve(style, colors: colors, isEnabled: true)
            XCTAssertEqual(result.elevation != .flat, style == .elevated, "\(style)")
        }
    }

    func testDisabledLooksTheSameForEveryFilledStyle() {
        for style in TKButton.Style.allCases where style != .outline {
            let result = TKButtonColors.resolve(style, colors: colors, isEnabled: false)
            XCTAssertEqual(result.background, colors.actionDisabled, "\(style)")
            XCTAssertEqual(result.foreground, colors.actionOnDisabled, "\(style)")
            XCTAssertNil(result.edge, "\(style)")
            XCTAssertEqual(result.elevation, .flat, "\(style)")
        }
        let outline = TKButtonColors.resolve(.outline, colors: colors, isEnabled: false)
        XCTAssertNil(outline.background)
        XCTAssertEqual(outline.border, colors.actionDisabled)
    }

    func testSizesMatchFigma() {
        XCTAssertEqual(TKButton.Size.allCases.map(\.height), [65, 58, 50, 43])
    }
}

final class TKFieldAppearanceTests: XCTestCase {
    private let colors = Theme.base.colors

    func testIdleFieldIsFilledWithoutBorder() {
        let look = TKFieldAppearance.resolve(status: .normal, isFocused: false, isEnabled: true, colors: colors)
        XCTAssertEqual(look.background, colors.surfaceInput)
        XCTAssertNil(look.border)
        XCTAssertNil(look.messageTint)
    }

    func testFocusAddsBrandBorder() {
        let look = TKFieldAppearance.resolve(status: .normal, isFocused: true, isEnabled: true, colors: colors)
        XCTAssertEqual(look.border, colors.actionPrimary)
    }

    func testErrorBeatsFocus() {
        let look = TKFieldAppearance.resolve(status: .error("Sai"), isFocused: true, isEnabled: true, colors: colors)
        XCTAssertEqual(look.border, colors.feedbackError)
        XCTAssertEqual(look.messageTint, colors.feedbackError)
    }

    func testSuccessUsesSuccessColour() {
        let look = TKFieldAppearance.resolve(status: .success("Ok"), isFocused: false, isEnabled: true, colors: colors)
        XCTAssertEqual(look.border, colors.feedbackSuccess)
    }

    func testDisabledHidesStatus() {
        let look = TKFieldAppearance.resolve(status: .error("Sai"), isFocused: false, isEnabled: false, colors: colors)
        XCTAssertEqual(look.background, colors.surfaceDisabled)
        XCTAssertNil(look.border)
        XCTAssertNil(look.messageTint)
    }

    func testStatusMessage() {
        XCTAssertNil(TKFieldStatus.normal.message)
        XCTAssertEqual(TKFieldStatus.error("Sai email").message, "Sai email")
        XCTAssertTrue(TKFieldStatus.error("x").isError)
        XCTAssertFalse(TKFieldStatus.success("x").isError)
    }
}

final class TKToastTests: XCTestCase {
    func testEachStyleUsesItsFeedbackColour() {
        let colors = Theme.base.colors
        XCTAssertEqual(TKToast("a", style: .info).tint(in: colors), colors.feedbackInfo)
        XCTAssertEqual(TKToast("a", style: .success).tint(in: colors), colors.feedbackSuccess)
        XCTAssertEqual(TKToast("a", style: .warning).tint(in: colors), colors.feedbackWarning)
        XCTAssertEqual(TKToast("a", style: .error).tint(in: colors), colors.feedbackError)
    }

    func testTwoToastsWithTheSameTextAreDifferent() {
        XCTAssertNotEqual(TKToast("Đã lưu"), TKToast("Đã lưu"))
    }
}
