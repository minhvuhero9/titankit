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

    func testAIServerNeedsAnHTTPSURL() {
        let config = AppConfig(infoDictionary: [
            "DolingoAIBaseURL": "https://dolingo-ai.example.workers.dev",
            "DolingoAIClientKey": "key",
        ])
        XCTAssertEqual(config.aiBaseURL?.host, "dolingo-ai.example.workers.dev")
        XCTAssertEqual(config.aiClientKey, "key")
        XCTAssertNil(AppConfig(infoDictionary: ["DolingoAIBaseURL": ""]).aiBaseURL)
        XCTAssertNil(AppConfig(infoDictionary: ["DolingoAIBaseURL": "http://insecure.example.com"]).aiBaseURL)
    }

    func testLegalPagesComeFromTheConfiguredServer() {
        XCTAssertEqual(AppConfig.legalURL("privacy", base: "https://dolingo-ai.example.workers.dev").absoluteString,
                       "https://dolingo-ai.example.workers.dev/privacy")
        XCTAssertEqual(AppConfig.legalURL("terms", base: "").absoluteString, "https://www.example.com/terms")
        XCTAssertEqual(AppConfig.legalURL("terms", base: nil).host, "www.example.com")
    }
}
