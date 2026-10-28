import TitanCore

/// Sells products and tells the app whether the user has premium.
/// Every call throws only TitanError: `.network(.offline)`, `.notFound` for an unknown product,
/// `.unknown` for anything the store reports.
///
///     let purchase = StoreKitPurchaseService(config: AppConfig.purchase)
///     purchase.start()
///     for await entitlements in purchase.entitlementStream { isPremium = entitlements.isPremium }
public protocol PurchaseService: Sendable {
    var entitlements: Entitlements { get }
    /// A new stream on each access. It starts with the current entitlements, then sends every change.
    var entitlementStream: AsyncStream<Entitlements> { get }

    /// Called once at launch: reads what the user owns and listens for renewals and refunds.
    func start()
    func products(ids: [String]) async throws(TitanError) -> [StoreProduct]
    func purchase(_ productId: String) async throws(TitanError) -> PurchaseResult
    /// "Restore purchases": syncs with the App Store and returns what the user owns.
    func restore() async throws(TitanError) -> Entitlements
}
