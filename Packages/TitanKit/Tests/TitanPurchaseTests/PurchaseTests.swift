import XCTest
import TitanCore
@testable import TitanPurchase

final class EntitlementRulesTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let config = PurchaseConfig(productIds: ["monthly", "lifetime", "coins"], premiumProductIds: ["monthly", "lifetime"])

    private typealias Owned = StoreKitPurchaseService.OwnedProduct

    func testNothingOwnedIsNotPremium() {
        XCTAssertEqual(StoreKitPurchaseService.entitlements(from: [], config: config, now: now), .none)
    }

    func testActiveSubscriptionIsPremiumUntilItExpires() {
        let expiry = now.addingTimeInterval(3600)
        let owned = [Owned(productId: "monthly", expirationDate: expiry)]
        let entitlements = StoreKitPurchaseService.entitlements(from: owned, config: config, now: now)
        XCTAssertEqual(entitlements, Entitlements(isPremium: true, activeProductIds: ["monthly"], expiresAt: expiry))

        let later = StoreKitPurchaseService.entitlements(from: owned, config: config, now: expiry)
        XCTAssertFalse(later.isPremium)
        XCTAssertTrue(later.activeProductIds.isEmpty)
    }

    func testRefundedPurchaseDoesNotCount() {
        let owned = [Owned(productId: "lifetime", revocationDate: now)]
        XCTAssertFalse(StoreKitPurchaseService.entitlements(from: owned, config: config, now: now).isPremium)
    }

    func testOnlyPremiumProductsUnlockPremium() {
        let owned = [Owned(productId: "coins")]
        let entitlements = StoreKitPurchaseService.entitlements(from: owned, config: config, now: now)
        XCTAssertFalse(entitlements.isPremium)
        XCTAssertEqual(entitlements.activeProductIds, ["coins"])
    }

    func testLifetimePurchaseHasNoExpiry() {
        let owned = [
            Owned(productId: "monthly", expirationDate: now.addingTimeInterval(3600)),
            Owned(productId: "lifetime"),
        ]
        let entitlements = StoreKitPurchaseService.entitlements(from: owned, config: config, now: now)
        XCTAssertTrue(entitlements.isPremium)
        XCTAssertNil(entitlements.expiresAt)
    }

    func testSubscriptionOnlyConfigMakesEveryProductPremium() {
        let config = PurchaseConfig(premiumProductIds: ["a", "b"])
        XCTAssertEqual(config.productIds, ["a", "b"])
        XCTAssertEqual(config.premiumProductIds, ["a", "b"])
    }
}

final class EntitlementBroadcasterTests: XCTestCase {
    func testStreamStartsWithCurrentValueAndSkipsRepeats() async {
        let broadcaster = EntitlementBroadcaster()
        var iterator = broadcaster.stream().makeAsyncIterator()
        let first = await iterator.next()
        XCTAssertEqual(first, Entitlements.none)

        let premium = Entitlements(isPremium: true, activeProductIds: ["monthly"])
        broadcaster.send(.none)
        broadcaster.send(premium)
        let second = await iterator.next()
        XCTAssertEqual(second, premium)
        XCTAssertEqual(broadcaster.value, premium)
    }

    func testCacheRoundTrip() {
        let defaults = UserDefaults(suiteName: "EntitlementCacheTests")!
        defaults.removePersistentDomain(forName: "EntitlementCacheTests")
        let cache = UserDefaultsEntitlementCache(defaults: defaults)
        XCTAssertNil(cache.load())
        let premium = Entitlements(isPremium: true, activeProductIds: ["yearly"], expiresAt: Date(timeIntervalSince1970: 1_900_000_000))
        cache.save(premium)
        XCTAssertEqual(cache.load(), premium)
    }
}

final class MockPurchaseServiceTests: XCTestCase {
    func testListsProductsInTheRequestedOrder() async throws {
        let purchase = MockPurchaseService()
        let products = try await purchase.products(ids: ["premium.yearly", "missing", "premium.monthly"])
        XCTAssertEqual(products.map(\.id), ["premium.yearly", "premium.monthly"])
        XCTAssertEqual(products.last?.freeTrialDays, 7)
    }

    func testSuccessfulPurchaseUnlocksPremium() async throws {
        let purchase = MockPurchaseService()
        let result = try await purchase.purchase("premium.monthly")
        XCTAssertEqual(result, .success)
        XCTAssertTrue(purchase.entitlements.isPremium)
        XCTAssertEqual(purchase.purchasedProductIds, ["premium.monthly"])
    }

    func testCancelledPurchaseChangesNothing() async throws {
        let purchase = MockPurchaseService()
        purchase.nextResult = .cancelled
        let result = try await purchase.purchase("premium.monthly")
        XCTAssertEqual(result, .cancelled)
        XCTAssertFalse(purchase.entitlements.isPremium)
    }

    func testUnknownProductAndFailuresThrow() async {
        let purchase = MockPurchaseService()
        do {
            _ = try await purchase.purchase("nope")
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error, .notFound)
        }
        purchase.failCalls(with: .network(.offline))
        do {
            _ = try await purchase.restore()
            XCTFail("expected offline")
        } catch {
            XCTAssertEqual(error, .network(.offline))
        }
        XCTAssertEqual(purchase.restores, 1)
    }
}
