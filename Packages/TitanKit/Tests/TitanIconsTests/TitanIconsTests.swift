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

final class ExtraIconSetsTests: XCTestCase {
    func testEverySymbolLoadsAsTemplate() {
        for symbol in TKSymbol.allCases {
            let image = symbol.uiImage
            XCTAssertNotNil(image, "missing \(symbol.assetName)")
            XCTAssertEqual(image?.renderingMode, .alwaysTemplate, symbol.assetName)
        }
    }

    func testColourIconsKeepTheirColours() {
        for icon in TKColorIcon.allCases {
            let image = icon.uiImage
            XCTAssertNotNil(image, "missing \(icon.assetName)")
            XCTAssertNotEqual(image?.renderingMode, .alwaysTemplate, icon.assetName)
        }
    }

    func testKeywordNamedSymbolKeepsItsAssetName() {
        XCTAssertEqual(TKSymbol.switch.assetName, "symbol.switch")
    }
}
