import XCTest
@testable import TitanNavigation

private enum TestRoute: Routable {
    case lesson(id: String)
    case settings
    case paywall
}

private enum TestTab: CaseIterable, Sendable {
    case home, profile
}

private struct TestParser: DeepLinkParser {
    func link(from url: URL) -> DeepLink<TestRoute>? {
        let segments = url.deepLinkSegments(webHosts: ["dolingo.app"])
        switch segments.first {
        case "lesson" where segments.count > 1: return DeepLink(route: .lesson(id: segments[1]))
        case "settings": return DeepLink(route: .settings)
        case "premium": return DeepLink(route: .paywall, presentation: .sheet)
        default: return nil
        }
    }
}

@MainActor
final class RouterTests: XCTestCase {
    func testPushPopAndPopToRoot() {
        let router = Router<TestRoute>()
        router.push(.settings)
        router.push(.lesson(id: "1"))
        XCTAssertEqual(router.path, [.settings, .lesson(id: "1")])
        router.pop()
        XCTAssertEqual(router.path, [.settings])
        router.popToRoot()
        XCTAssertTrue(router.path.isEmpty)
        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }

    func testPresentAndDismiss() {
        let router = Router<TestRoute>()
        router.present(.paywall)
        XCTAssertEqual(router.sheet, .paywall)
        XCTAssertNil(router.fullScreenCover)
        router.present(.settings, fullScreen: true)
        XCTAssertEqual(router.fullScreenCover, .settings)
        router.dismiss()
        XCTAssertNil(router.sheet)
        XCTAssertNil(router.fullScreenCover)
    }

    func testOpenClosesSheetThenPushes() {
        let router = Router<TestRoute>()
        router.present(.paywall)
        router.open(DeepLink(route: .lesson(id: "7")))
        XCTAssertNil(router.sheet)
        XCTAssertEqual(router.path, [.lesson(id: "7")])
    }

    func testOpenWithSheetPresentation() {
        let router = Router<TestRoute>()
        router.open(DeepLink(route: .paywall, presentation: .sheet))
        XCTAssertEqual(router.sheet, .paywall)
        XCTAssertTrue(router.path.isEmpty)
    }
}

@MainActor
final class TabRouterTests: XCTestCase {
    func testEachTabHasItsOwnStack() {
        let tabs = TabRouter<TestTab, TestRoute>(initial: .home)
        tabs.router(for: .home).push(.settings)
        XCTAssertTrue(tabs.router(for: .profile).path.isEmpty)
    }

    func testOpenSwitchesTabAndPushes() {
        let tabs = TabRouter<TestTab, TestRoute>(initial: .home)
        tabs.open(DeepLink(route: .lesson(id: "3")), in: .profile)
        XCTAssertEqual(tabs.selected, .profile)
        XCTAssertEqual(tabs.router(for: .profile).path, [.lesson(id: "3")])
    }

    func testSelectingCurrentTabPopsToRoot() {
        let tabs = TabRouter<TestTab, TestRoute>(initial: .home)
        tabs.router(for: .home).push(.settings)
        tabs.select(.home)
        XCTAssertTrue(tabs.router(for: .home).path.isEmpty)
        tabs.router(for: .home).push(.settings)
        tabs.select(.profile)
        XCTAssertEqual(tabs.router(for: .home).path, [.settings])
    }
}

@MainActor
final class DeepLinkTests: XCTestCase {
    private let parser = TestParser()

    func testParserTable() {
        let cases: [(String, DeepLink<TestRoute>?)] = [
            ("dolingo://lesson/42", DeepLink(route: .lesson(id: "42"))),
            ("https://dolingo.app/lesson/42", DeepLink(route: .lesson(id: "42"))),
            ("dolingo://settings", DeepLink(route: .settings)),
            ("dolingo://premium", DeepLink(route: .paywall, presentation: .sheet)),
            ("dolingo://lesson", nil),
            ("dolingo://unknown", nil),
            ("https://evil.example.com/lesson/42", nil),
        ]
        for (string, expected) in cases {
            XCTAssertEqual(parser.link(from: URL(string: string)!), expected, string)
        }
    }

    func testQueryParameters() {
        let url = URL(string: "dolingo://lesson/1?ref=push&ref=email&step=2")!
        XCTAssertEqual(url.queryParameters, ["ref": "email", "step": "2"])
    }

    func testHandlerForwardsOnlyKnownLinks() {
        var received: [DeepLink<TestRoute>] = []
        let handler = DeepLinkHandler(parser: parser) { received.append($0) }
        XCTAssertTrue(handler.handle(URL(string: "dolingo://settings")!))
        XCTAssertFalse(handler.handle(URL(string: "dolingo://nope")!))
        XCTAssertEqual(received, [DeepLink(route: .settings)])
    }
}
