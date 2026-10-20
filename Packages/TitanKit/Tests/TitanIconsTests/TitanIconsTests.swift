import UIKit
import XCTest
@testable import TitanIcons

final class TitanIconsTests: XCTestCase {
    func testEveryIconExistsInBothStyles() {
        for icon in TKIcon.allCases {
            for style in TKIconStyle.allCases {
                XCTAssertNotNil(icon.uiImage(style), "missing \(icon.assetName(style))")
            }
        }
    }

    func testIconsAreTemplates() throws {
        let image = try XCTUnwrap(TKIcon.home.uiImage())
        XCTAssertEqual(image.renderingMode, .alwaysTemplate)
    }

    func testAssetNameCombinesStyleAndIcon() {
        XCTAssertEqual(TKIcon.arrowLeft.assetName(.bold), "bold.arrowLeft")
    }
}
