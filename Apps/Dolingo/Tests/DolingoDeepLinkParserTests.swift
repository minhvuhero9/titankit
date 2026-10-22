import XCTest
import TitanNavigation
@testable import Dolingo

final class DolingoDeepLinkParserTests: XCTestCase {
    func testKnownAndUnknownLinks() {
        let parser = DolingoDeepLinkParser()
        XCTAssertEqual(parser.link(from: URL(string: "dolingo://catalog")!), DeepLink(route: .catalog))
        XCTAssertEqual(parser.link(from: URL(string: "dolingo://settings")!), DeepLink(route: .settings))
        XCTAssertNil(parser.link(from: URL(string: "dolingo://nope")!))
        XCTAssertNil(parser.link(from: URL(string: "otherapp://catalog")!))
    }

    @MainActor
    func testDeepLinkPushesOnTheAppRouter() {
        let container = AppContainer.preview()
        XCTAssertTrue(container.deepLinks.handle(URL(string: "dolingo://catalog")!))
        XCTAssertEqual(container.router.path, [.catalog])
    }

    func testSettingsRowsLeadToTheirScreens() {
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.profile), .profile)
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.appearance), .appearance)
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.privacy), .webPage(.privacy))
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.terms), .webPage(.terms))
        XCTAssertNil(DolingoSettings.route(for: "unknown"))
    }
}
