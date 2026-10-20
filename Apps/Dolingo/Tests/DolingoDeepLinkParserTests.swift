import XCTest
import TitanNavigation
@testable import Dolingo

final class DolingoDeepLinkParserTests: XCTestCase {
    func testKnownAndUnknownLinks() {
        let parser = DolingoDeepLinkParser()
        XCTAssertEqual(parser.link(from: URL(string: "dolingo://catalog")!), DeepLink(route: .catalog))
        XCTAssertNil(parser.link(from: URL(string: "dolingo://nope")!))
        XCTAssertNil(parser.link(from: URL(string: "otherapp://catalog")!))
    }

    @MainActor
    func testDeepLinkPushesOnTheAppRouter() {
        let container = AppContainer.preview()
        XCTAssertTrue(container.deepLinks.handle(URL(string: "dolingo://catalog")!))
        XCTAssertEqual(container.router.path, [.catalog])
    }
}
