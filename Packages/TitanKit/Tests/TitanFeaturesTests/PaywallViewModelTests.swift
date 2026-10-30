import XCTest
import TitanCore
import TitanLocalization
import TitanPurchase
@testable import TitanFeatures

@MainActor
final class PaywallViewModelTests: XCTestCase {
    private let ids = MockPurchaseService.sampleProducts.map(\.id)

    func testLoadsProductsInTheConfiguredOrder() async {
        let viewModel = PaywallViewModel(purchase: MockPurchaseService(), productIds: Array(ids.reversed()))
        await viewModel.load()
        XCTAssertEqual(viewModel.state.value?.map(\.id), Array(ids.reversed()))
    }

    func testUnknownProductsShowNotFound() async {
        let viewModel = PaywallViewModel(purchase: MockPurchaseService(), productIds: ["missing"])
        await viewModel.load()
        XCTAssertEqual(viewModel.state.error, .notFound)
    }

    func testOfflineLoadFails() async {
        let purchase = MockPurchaseService()
        purchase.failCalls(with: .network(.offline))
        let viewModel = PaywallViewModel(purchase: purchase, productIds: ids)
        await viewModel.load()
        XCTAssertEqual(viewModel.state.error, .network(.offline))
    }

    func testBuyingUnlocksPremium() async throws {
        let purchase = MockPurchaseService()
        let viewModel = PaywallViewModel(purchase: purchase, productIds: ids)
        await viewModel.load()
        let product = try XCTUnwrap(viewModel.state.value?.first)
        let bought = await viewModel.buy(product)
        XCTAssertTrue(bought)
        XCTAssertTrue(viewModel.entitlements.isPremium)
        XCTAssertTrue(viewModel.isOwned(product))
        XCTAssertNil(viewModel.purchasingId)
        XCTAssertEqual(purchase.purchasedProductIds, [product.id])
    }

    func testCancelledPurchaseShowsNothing() async throws {
        let purchase = MockPurchaseService()
        purchase.nextResult = .cancelled
        let viewModel = PaywallViewModel(purchase: purchase, productIds: ids)
        await viewModel.load()
        let bought = await viewModel.buy(try XCTUnwrap(viewModel.state.value?.first))
        XCTAssertFalse(bought)
        XCTAssertNil(viewModel.errorKey)
        XCTAssertNil(viewModel.noticeKey)
    }

    func testPendingPurchaseExplainsTheWait() async throws {
        let purchase = MockPurchaseService()
        purchase.nextResult = .pending
        let viewModel = PaywallViewModel(purchase: purchase, productIds: ids)
        await viewModel.load()
        let bought = await viewModel.buy(try XCTUnwrap(viewModel.state.value?.first))
        XCTAssertFalse(bought)
        XCTAssertEqual(viewModel.noticeKey, KitStrings.Paywall.pending)
    }

    func testFailedPurchaseShowsTheError() async throws {
        let purchase = MockPurchaseService()
        let viewModel = PaywallViewModel(purchase: purchase, productIds: ids)
        await viewModel.load()
        purchase.failCalls(with: .network(.offline))
        let bought = await viewModel.buy(try XCTUnwrap(viewModel.state.value?.first))
        XCTAssertFalse(bought)
        XCTAssertEqual(viewModel.errorKey, TitanError.network(.offline).messageKey)
    }

    func testRestoreWithPremiumSucceeds() async {
        let owned = Entitlements(isPremium: true, activeProductIds: [ids[0]])
        let purchase = MockPurchaseService(entitlements: owned)
        let viewModel = PaywallViewModel(purchase: purchase, productIds: ids)
        let restored = await viewModel.restore()
        XCTAssertTrue(restored)
        XCTAssertEqual(viewModel.entitlements, owned)
        XCTAssertEqual(purchase.restores, 1)
        XCTAssertFalse(viewModel.isRestoring)
    }

    func testRestoreWithNothingSaysSo() async {
        let viewModel = PaywallViewModel(purchase: MockPurchaseService(), productIds: ids)
        let restored = await viewModel.restore()
        XCTAssertFalse(restored)
        XCTAssertEqual(viewModel.noticeKey, KitStrings.Paywall.nothingToRestore)
    }

    func testEveryPaywallStringExistsInBothLanguages() {
        let keys = [
            KitStrings.Paywall.title, KitStrings.Paywall.message, KitStrings.Paywall.close,
            KitStrings.Paywall.popular, KitStrings.Paywall.choose, KitStrings.Paywall.startTrial,
            KitStrings.Paywall.perDay, KitStrings.Paywall.perWeek, KitStrings.Paywall.perMonth,
            KitStrings.Paywall.perYear, KitStrings.Paywall.trial, KitStrings.Paywall.autoRenew,
            KitStrings.Paywall.restore, KitStrings.Paywall.nothingToRestore, KitStrings.Paywall.pending,
            KitStrings.Paywall.upgradePlan, KitStrings.Paywall.monthly, KitStrings.Paywall.yearly,
            KitStrings.Paywall.save, KitStrings.Paywall.continuePrice,
        ]
        for key in keys {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }

    func testTrialLineNamesTheDaysAndThePriceAfter() {
        let format = KitStrings.string(KitStrings.Paywall.trial, locale: Locale(identifier: "en"))
        XCTAssertEqual(String(format: format, 7, "$9.99 / month"), "Free for 7 days, then $9.99 / month")
    }

    func testTheYearlyPlanShowsWhatItSaves() {
        let monthly = StoreProduct(id: "m", displayName: "Monthly", displayPrice: "$4.99", price: 4.99,
                                   kind: .autoRenewable, subscriptionPeriod: .month)
        let yearly = StoreProduct(id: "y", displayName: "Yearly", displayPrice: "$49.99", price: 49.99,
                                  kind: .autoRenewable, subscriptionPeriod: .year)
        // Figma: $4.99 a month, $49.99 a year, "Save 17%".
        XCTAssertEqual(PaywallViewModel.savingsPercent(of: yearly, in: [monthly, yearly]), 17)
        XCTAssertNil(PaywallViewModel.savingsPercent(of: monthly, in: [monthly, yearly]))
        XCTAssertNil(PaywallViewModel.savingsPercent(of: yearly, in: [yearly]))
        let pricey = StoreProduct(id: "p", displayName: "Yearly", displayPrice: "$59.88", price: 59.88,
                                  kind: .autoRenewable, subscriptionPeriod: .year)
        XCTAssertNil(PaywallViewModel.savingsPercent(of: pricey, in: [monthly, pricey]))
    }
}
