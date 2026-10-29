import XCTest
import TitanCore
import TitanFeatures
import TitanPurchase
@testable import Dolingo

final class AppConfigTests: XCTestCase {
    func testReadsEnvironmentFromInfoPlist() {
        let config = AppConfig(infoDictionary: [
            "TitanAppEnvironment": "staging",
            "TitanAPIBaseURL": "https://api-staging.example.com",
            "CFBundleShortVersionString": "1.4.2",
        ])
        XCTAssertEqual(config.environment, .staging)
        XCTAssertEqual(config.appVersion, "1.4.2")
        XCTAssertEqual(config.apiBaseURL.host, "api-staging.example.com")
    }

    func testUnknownEnvironmentFallsBackToDev() {
        let config = AppConfig(infoDictionary: ["TitanAppEnvironment": "bogus"])
        XCTAssertEqual(config.environment, .dev)
    }

    func testPremiumProductsUseTheBundlePrefix() {
        XCTAssertEqual(AppConfig.purchase.productIds.count, 2)
        XCTAssertTrue(AppConfig.purchase.productIds.allSatisfy { $0.hasPrefix("com.titanstudio.dolingo.premium.") })
        XCTAssertEqual(Set(AppConfig.purchase.productIds), AppConfig.purchase.premiumProductIds)
    }

    func testPaywallSellsThePremiumProducts() {
        XCTAssertEqual(AppConfig.paywall.productIds, AppConfig.purchase.productIds)
        let highlighted = AppConfig.paywall.highlightedProductId
        XCTAssertTrue(AppConfig.purchase.productIds.contains(highlighted ?? ""))
        XCTAssertEqual(AppConfig.paywall.termsURL, AppConfig.termsURL)
        XCTAssertEqual(AppConfig.paywall.privacyURL, AppConfig.privacyURL)
    }
}
