import Foundation
import TitanCore

/// Purchases for tests, previews and the simulator before products exist on App Store Connect.
///
///     let purchase = MockPurchaseService(products: MockPurchaseService.sampleProducts)
///     purchase.nextResult = .cancelled
public final class MockPurchaseService: PurchaseService, @unchecked Sendable {
    // @unchecked: all state is guarded by `lock`; the broadcaster locks itself.
    private let lock = NSLock()
    private let config: PurchaseConfig
    private let broadcaster: EntitlementBroadcaster
    private var storeProducts: [StoreProduct]
    private var result: PurchaseResult = .success
    private var error: TitanError?
    private var delay: Duration
    private var purchased: [String] = []
    private var restoreCount = 0

    /// - Parameters:
    ///   - config: nil makes every product premium.
    ///   - delay: how long each call takes, to see loading states.
    public init(
        products: [StoreProduct] = MockPurchaseService.sampleProducts,
        config: PurchaseConfig? = nil,
        entitlements: Entitlements = .none,
        delay: Duration = .zero
    ) {
        storeProducts = products
        self.config = config ?? PurchaseConfig(premiumProductIds: products.map(\.id))
        broadcaster = EntitlementBroadcaster(entitlements)
        self.delay = delay
    }

    public var entitlements: Entitlements { broadcaster.value }
    public var entitlementStream: AsyncStream<Entitlements> { broadcaster.stream() }

    public func start() {}

    public func products(ids: [String]) async throws(TitanError) -> [StoreProduct] {
        try await wait()
        let all = lock.withLock { storeProducts }
        return ids.compactMap { id in all.first { $0.id == id } }
    }

    public func purchase(_ productId: String) async throws(TitanError) -> PurchaseResult {
        try await wait()
        let (known, result) = lock.withLock { (storeProducts.contains { $0.id == productId }, self.result) }
        guard known else { throw .notFound }
        guard result == .success else { return result }
        lock.withLock { purchased.append(productId) }
        var owned = entitlements
        owned.activeProductIds.insert(productId)
        owned.isPremium = owned.isPremium || config.premiumProductIds.contains(productId)
        broadcaster.send(owned)
        return .success
    }

    public func restore() async throws(TitanError) -> Entitlements {
        lock.withLock { restoreCount += 1 }
        try await wait()
        return entitlements
    }

    // MARK: - Controls for tests

    /// What the next purchases return; `.success` by default.
    public var nextResult: PurchaseResult {
        get { lock.withLock { result } }
        set { lock.withLock { result = newValue } }
    }

    /// Thrown by every call until set back to nil.
    public func failCalls(with error: TitanError?) {
        lock.withLock { self.error = error }
    }

    /// Changes what the user owns, e.g. a subscription that ran out.
    public func setEntitlements(_ entitlements: Entitlements) {
        broadcaster.send(entitlements)
    }

    public var purchasedProductIds: [String] {
        lock.withLock { purchased }
    }

    public var restores: Int {
        lock.withLock { restoreCount }
    }

    private func wait() async throws(TitanError) {
        let (delay, error) = lock.withLock { (self.delay, self.error) }
        if delay > .zero {
            do { try await Task.sleep(for: delay) } catch { throw .cancelled }
        }
        if let error { throw error }
    }

    /// A monthly plan with a 7 day trial and a yearly plan, for previews.
    public static let sampleProducts = [
        StoreProduct(id: "premium.monthly", displayName: "Premium Monthly", displayPrice: "$9.99",
                     price: 9.99, kind: .autoRenewable, subscriptionPeriod: .month, freeTrialDays: 7),
        StoreProduct(id: "premium.yearly", displayName: "Premium Yearly", displayPrice: "$59.99",
                     price: 59.99, kind: .autoRenewable, subscriptionPeriod: .year),
    ]
}
