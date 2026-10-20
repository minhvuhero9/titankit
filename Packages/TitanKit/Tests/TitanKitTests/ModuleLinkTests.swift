import XCTest
import TitanAds
import TitanAnalytics
import TitanAuth
import TitanCore
import TitanDesignSystem
import TitanFeatures
import TitanLocalization
import TitanNavigation
import TitanNetworking
import TitanPurchase
import TitanPush
import TitanRemoteConfig
import TitanStorage

/// Phase 0 smoke test: every module builds and links.
final class ModuleLinkTests: XCTestCase {
    func testAllModulesLink() {
        let names = [
            TitanCoreModule.moduleName, TitanNetworkingModule.moduleName, TitanStorageModule.moduleName,
            TitanDesignSystemModule.moduleName, TitanNavigationModule.moduleName, TitanAuthModule.moduleName,
            TitanPurchaseModule.moduleName, TitanAdsModule.moduleName, TitanAnalyticsModule.moduleName,
            TitanPushModule.moduleName, TitanRemoteConfigModule.moduleName, TitanLocalizationModule.moduleName,
            TitanFeaturesModule.moduleName,
        ]
        XCTAssertEqual(Set(names).count, 13)
    }

    func testKitVersionIsSemver() {
        XCTAssertEqual(TitanCoreModule.version.split(separator: ".").count, 3)
    }
}
