import XCTest
import TitanNavigation
@testable import Dolingo

final class DolingoDeepLinkParserTests: XCTestCase {
    func testKnownAndUnknownLinks() {
        let parser = DolingoDeepLinkParser()
        XCTAssertEqual(parser.link(from: URL(string: "dolingo://catalog")!), DeepLink(route: .catalog))
        XCTAssertEqual(parser.link(from: URL(string: "dolingo://settings")!), DeepLink(route: .settings))
        XCTAssertEqual(parser.link(from: URL(string: "dolingo://premium")!), DeepLink(route: .paywall, presentation: .sheet))
        XCTAssertNil(parser.link(from: URL(string: "dolingo://nope")!))
        XCTAssertNil(parser.link(from: URL(string: "otherapp://catalog")!))
    }

    @MainActor
    func testDeepLinkPushesOnTheAppRouter() {
        let container = AppContainer.preview()
        XCTAssertTrue(container.deepLinks.handle(URL(string: "dolingo://catalog")!))
        XCTAssertEqual(container.router.path, [.catalog])
    }

    @MainActor
    func testSettingsLinkOpensTheAccountTab() {
        let container = AppContainer.preview()
        XCTAssertTrue(container.deepLinks.handle(URL(string: "dolingo://settings")!))
        XCTAssertEqual(container.tabs.selected, .account)
    }

    @MainActor
    func testPremiumLinkOpensThePaywallInASheet() {
        let container = AppContainer.preview()
        XCTAssertTrue(container.deepLinks.handle(URL(string: "dolingo://premium")!))
        XCTAssertEqual(container.router.sheet, .paywall)
        XCTAssertTrue(container.router.path.isEmpty)
    }

    func testSettingsRowsLeadToTheirScreens() {
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.profile), .profile)
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.appearance), .appearance)
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.privacy), .webPage(.privacy))
        XCTAssertEqual(DolingoSettings.route(for: DolingoSettings.terms), .webPage(.terms))
        // Opens the App Store review page instead of a screen.
        XCTAssertNil(DolingoSettings.route(for: DolingoSettings.rateApp))
        XCTAssertNil(DolingoSettings.route(for: "unknown"))
    }
}
