import XCTest
@testable import TitanDesignSystem

final class FeedbackDisplayTests: XCTestCase {
    private let colors = Theme.base.colors

    func testAlertUsesStatusColourOnAPaleTint() {
        let expected: [TKAlert.Status: AdaptiveColor] = [
            .info: colors.actionPrimary,
            .success: colors.feedbackSuccess,
            .warning: colors.feedbackWarning,
            .error: colors.feedbackError,
        ]
        for status in TKAlert.Status.allCases {
            let look = TKAlertColors.resolve(status: status, colors: colors)
            XCTAssertEqual(look.foreground, expected[status], status.rawValue)
            XCTAssertEqual(look.background.light, expected[status]?.light.opacity(0.08), status.rawValue)
            XCTAssertEqual(look.background.dark, expected[status]?.dark.opacity(0.08), status.rawValue)
        }
    }

    func testAvatarInitials() {
        XCTAssertEqual(TKAvatar.initials(from: "Nguyễn Văn An"), "NA")
        XCTAssertEqual(TKAvatar.initials(from: "  jack  "), "J")
        XCTAssertEqual(TKAvatar.initials(from: "đỗ minh"), "ĐM")
        XCTAssertEqual(TKAvatar.initials(from: ""), "")
    }
}
