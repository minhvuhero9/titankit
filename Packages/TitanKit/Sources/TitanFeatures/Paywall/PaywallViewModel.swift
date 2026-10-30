import Foundation
import TitanCore
import TitanLocalization
import TitanPurchase

/// Loads the plans, buys one or restores what the user already owns.
@MainActor
public final class PaywallViewModel: ObservableObject {
    @Published public private(set) var state: LoadState<[StoreProduct]> = .idle
    @Published public private(set) var entitlements: Entitlements
    /// The product being bought, for the spinner on its card.
    @Published public private(set) var purchasingId: String?
    @Published public private(set) var isRestoring = false
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?
    /// Kit string key of a message that is not an error, e.g. a purchase waiting for approval.
    @Published public private(set) var noticeKey: String?

    private let purchase: any PurchaseService
    private let productIds: [String]

    public init(purchase: any PurchaseService, productIds: [String]) {
        self.purchase = purchase
        self.productIds = productIds
        entitlements = purchase.entitlements
    }

    /// True while a purchase or a restore runs; the other buttons wait.
    public var isBusy: Bool {
        purchasingId != nil || isRestoring
    }

    public func load() async {
        state = .loading
        do {
            let products = try await purchase.products(ids: productIds)
            // No product means the ids are wrong or not on App Store Connect yet.
            state = products.isEmpty ? .failed(.notFound) : .loaded(products)
        } catch {
            state = .failed(error)
        }
    }

    /// Keeps `entitlements` current, e.g. when an Ask to Buy purchase is approved. Run it with `.task`.
    public func observeEntitlements() async {
        for await value in purchase.entitlementStream {
            entitlements = value
        }
    }

    public func isOwned(_ product: StoreProduct) -> Bool {
        entitlements.activeProductIds.contains(product.id)
    }

    /// True when the product was bought; false when it was cancelled, is waiting or failed.
    public func buy(_ product: StoreProduct) async -> Bool {
        guard !isBusy else { return false }
        errorKey = nil
        noticeKey = nil
        purchasingId = product.id
        defer { purchasingId = nil }
        do {
            switch try await purchase.purchase(product.id) {
            case .success:
                entitlements = purchase.entitlements
                return true
            case .pending:
                noticeKey = KitStrings.Paywall.pending
                return false
            case .cancelled:
                return false
            }
        } catch {
            errorKey = error == .cancelled ? nil : error.messageKey
            return false
        }
    }

    /// True when the restore gave the user premium.
    public func restore() async -> Bool {
        guard !isBusy else { return false }
        errorKey = nil
        noticeKey = nil
        isRestoring = true
        defer { isRestoring = false }
        do {
            let restored = try await purchase.restore()
            entitlements = restored
            if !restored.isPremium { noticeKey = KitStrings.Paywall.nothingToRestore }
            return restored.isPremium
        } catch {
            errorKey = error == .cancelled ? nil : error.messageKey
            return false
        }
    }

    /// Percent a yearly plan saves against twelve months of the monthly plan, rounded like Figma's
    /// "Save 17%" ($49.99 against 12 × $4.99); nil without both plans or below 1 %.
    public nonisolated static func savingsPercent(of product: StoreProduct, in products: [StoreProduct]) -> Int? {
        guard product.subscriptionPeriod == .year,
              let monthly = products.first(where: { $0.subscriptionPeriod == .month }),
              monthly.price > 0 else { return nil }
        let twelveMonths = monthly.price * 12
        let saved = NSDecimalNumber(decimal: (twelveMonths - product.price) / twelveMonths * 100).doubleValue
        let percent = Int(saved.rounded())
        return percent >= 1 ? percent : nil
    }
}
