import XCTest
@testable import TitanDesignSystem

final class RGBATests: XCTestCase {
    func testHexParsing() {
        let color = RGBA(hex: 0x5150FF)
        XCTAssertEqual(color.red, 81.0 / 255, accuracy: 0.0001)
        XCTAssertEqual(color.green, 80.0 / 255, accuracy: 0.0001)
        XCTAssertEqual(color.blue, 1, accuracy: 0.0001)
    }

    func testContrastMatchesWCAG() {
        XCTAssertEqual(RGBA.black.contrast(with: .white), 21, accuracy: 0.01)
        XCTAssertEqual(RGBA.white.contrast(with: .white), 1, accuracy: 0.01)
    }

    func testReadableForegroundPicksTheBetterOne() {
        XCTAssertEqual(RGBA(hex: 0x5150FF).readableForeground, .white)
        XCTAssertEqual(RGBA(hex: 0xFACC15).readableForeground, .black)
    }
}

final class ColorScaleTests: XCTestCase {
    func testHexListFillsEveryStep() {
        let scale = ColorScale([0xEEEEFF, 0xDCDCFF, 0xCBCBFF, 0xB9B9FF, 0xA8A8FF,
                                0x9796FF, 0x8585FF, 0x7473FF, 0x6262FF, 0x5150FF])
        XCTAssertEqual(scale[50], RGBA(hex: 0xEEEEFF))
        XCTAssertEqual(scale[900], RGBA(hex: 0x5150FF))
    }
}

final class PaletteGeneratorTests: XCTestCase {
    private let brands: [UInt32] = [0x2F5BEA, 0x5150FF, 0xFF6B00, 0x12D18E, 0xFACC15, 0x808080, 0xE11D48]

    func testScaleGetsDarkerStepByStep() {
        for hex in brands {
            let scale = PaletteGenerator.scale(from: RGBA(hex: hex))
            let luminances = ColorScale.steps.map { scale[$0].luminance }
            XCTAssertEqual(luminances, luminances.sorted(by: >), "Brand \(String(hex, radix: 16))")
        }
    }

    func testTextOnPrimaryIsReadable() {
        for hex in brands {
            let tokens = PaletteGenerator.tokens(from: RGBA(hex: hex))
            for mode in [\AdaptiveColor.light, \AdaptiveColor.dark] {
                let ratio = tokens.actionOnPrimary[keyPath: mode].contrast(with: tokens.actionPrimary[keyPath: mode])
                XCTAssertGreaterThanOrEqual(ratio, 4.5, "Brand \(String(hex, radix: 16))")
            }
        }
    }

    func testBodyTextIsReadableOnBackground() {
        let tokens = PaletteGenerator.tokens(from: RGBA(hex: 0x2F5BEA))
        XCTAssertGreaterThanOrEqual(tokens.textPrimary.light.contrast(with: tokens.surfaceBackground.light), 4.5)
        XCTAssertGreaterThanOrEqual(tokens.textPrimary.dark.contrast(with: tokens.surfaceBackground.dark), 4.5)
        XCTAssertGreaterThanOrEqual(tokens.textSecondary.light.contrast(with: tokens.surfaceBackground.light), 4.5)
        XCTAssertGreaterThanOrEqual(tokens.textSecondary.dark.contrast(with: tokens.surfaceBackground.dark), 4.5)
    }

    func testHSLRoundTrip() {
        let original = RGBA(hex: 0x5150FF)
        let (h, s, l) = PaletteGenerator.hsl(original)
        let back = PaletteGenerator.rgb(hue: h, saturation: s, lightness: l)
        XCTAssertEqual(back.red, original.red, accuracy: 0.001)
        XCTAssertEqual(back.green, original.green, accuracy: 0.001)
        XCTAssertEqual(back.blue, original.blue, accuracy: 0.001)
    }
}

final class ThemeTests: XCTestCase {
    func testEmptyPatchKeepsEverything() {
        XCTAssertEqual(Theme.base.merged(with: ThemePatch()), Theme.base)
    }

    func testLaterLayerWinsOnlyForFieldsItSets() {
        var colors = ColorTokensPatch()
        colors.actionPrimary = AdaptiveColor(RGBA(hex: 0x5150FF))
        let brand = ThemePatch(colors: colors, fontFamily: "Urbanist", radius: .soft)

        let theme = Theme.base.merged(with: brand)

        XCTAssertEqual(theme.colors.actionPrimary, AdaptiveColor(RGBA(hex: 0x5150FF)))
        XCTAssertEqual(theme.colors.textPrimary, Theme.base.colors.textPrimary)
        XCTAssertEqual(theme.typography.fontFamily, "Urbanist")
        XCTAssertEqual(theme.radius, .soft)
    }

    func testOverrideBeatsBrand() {
        let brand = ThemePatch(fontFamily: "Inter", radius: .soft)
        let override = ThemePatch(radius: .sharp)

        let theme = Theme.base.merged(with: brand).merged(with: override)

        XCTAssertEqual(theme.typography.fontFamily, "Inter")
        XCTAssertEqual(theme.radius, .sharp)
    }

    func testTextStylePatchReplacesOnlyGivenRoles() {
        let patch = ThemePatch(textStyles: [.display: TextStyle(size: 48, weight: .bold)])
        let theme = Theme.base.merged(with: patch)

        XCTAssertEqual(theme.typography.style(.display).size, 48)
        XCTAssertEqual(theme.typography.style(.body), Typography.base.style(.body))
    }

    func testLineSpacingFollowsLineHeight() {
        let typography = Typography(styles: Dictionary(uniqueKeysWithValues: TextRole.allCases.map {
            ($0, TextStyle(size: 20, weight: .regular, lineHeight: 1.5))
        }))
        XCTAssertEqual(typography.lineSpacing(.body), 10, accuracy: 0.001)
    }
}
