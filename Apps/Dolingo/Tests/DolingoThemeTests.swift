import XCTest
import TitanDesignSystem
@testable import Dolingo

final class DolingoThemeTests: XCTestCase {
    private let colors = DolingoTheme.theme.colors

    func testKeepsFigmaBrandColour() {
        XCTAssertEqual(colors.actionPrimary, AdaptiveColor(RGBA(hex: 0x5150FF)))
    }

    /// WCAG AA (4.5:1) for button labels and body text, in both modes.
    func testMainTextIsReadable() {
        let pairs: [(String, AdaptiveColor, AdaptiveColor)] = [
            ("onPrimary", colors.actionOnPrimary, colors.actionPrimary),
            ("onSecondary", colors.actionOnSecondary, colors.actionSecondary),
            ("onNeutral", colors.actionOnNeutral, colors.actionNeutral),
            ("text", colors.textPrimary, colors.surfaceBackground),
            ("secondaryText", colors.textSecondary, colors.surfaceBackground),
        ]
        for (name, foreground, background) in pairs {
            XCTAssertGreaterThanOrEqual(foreground.light.contrast(with: background.light), 4.5, "\(name) light")
            XCTAssertGreaterThanOrEqual(foreground.dark.contrast(with: background.dark), 4.5, "\(name) dark")
        }
    }
}
