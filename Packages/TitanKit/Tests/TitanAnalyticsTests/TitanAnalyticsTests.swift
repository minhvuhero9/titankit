import XCTest
import TitanCore
@testable import TitanAnalytics

final class AnalyticsTests: XCTestCase {
    func testEventNamesFollowTheRules() {
        XCTAssertTrue(AnalyticsEvent.isValidName("paywall_viewed"))
        XCTAssertTrue(AnalyticsEvent.isValidName("lesson_2_done"))
        XCTAssertFalse(AnalyticsEvent.isValidName("PaywallViewed"))
        XCTAssertFalse(AnalyticsEvent.isValidName("_hidden"))
        XCTAssertFalse(AnalyticsEvent.isValidName("paywall-viewed"))
        XCTAssertFalse(AnalyticsEvent.isValidName(String(repeating: "a", count: 41)))
        for event in [AnalyticsEvent.login(method: "apple"), .signUp(method: "email"), .paywallViewed(source: "home"),
                      .purchaseCompleted(productId: "p"), .passwordReset, .accountDeleted] {
            XCTAssertTrue(AnalyticsEvent.isValidName(event.name), event.name)
        }
    }

    func testCompositeSendsToEveryService() {
        let first = SpyAnalyticsService()
        let second = SpyAnalyticsService()
        let analytics = CompositeAnalyticsService([first, second])
        analytics.track(.login(method: "email"))
        analytics.screen("home")
        analytics.setUserId("42")
        analytics.setCollectionEnabled(false)
        for spy in [first, second] {
            XCTAssertEqual(spy.events, [.login(method: "email")])
            XCTAssertEqual(spy.screens, ["home"])
            XCTAssertEqual(spy.userId, "42")
            XCTAssertFalse(spy.isCollectionEnabled)
        }
    }

    func testConsoleLogsTheEvent() {
        let logger = MockLogger()
        ConsoleAnalyticsService(logger: logger).track(.paywallViewed(source: "home"))
        XCTAssertTrue(logger.entries.map(\.message).contains { $0.contains("paywall_viewed") && $0.contains("source=home") })
    }
}
