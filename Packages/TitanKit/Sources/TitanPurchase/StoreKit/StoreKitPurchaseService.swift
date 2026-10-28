import Foundation
import StoreKit
import TitanCore

/// PurchaseService on StoreKit 2. Only verified transactions count, and each one is
/// finished after the entitlements are updated.
public final class StoreKitPurchaseService: PurchaseService, @unchecked Sendable {
    // @unchecked: mutable state is guarded by `lock`; the broadcaster locks itself.
    private let config: PurchaseConfig
    private let cache: any EntitlementCache
    private let logger: (any Logging)?
    private let broadcaster: EntitlementBroadcaster
    private let lock = NSLock()
    private var loadedProducts: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?

    public init(config: PurchaseConfig, cache: any EntitlementCache = UserDefaultsEntitlementCache(), logger: (any Logging)? = nil) {
        self.config = config
        self.cache = cache
        self.logger = logger
        broadcaster = EntitlementBroadcaster(cache.load() ?? .none)
    }

    deinit {
        updatesTask?.cancel()
    }

    public var entitlements: Entitlements { broadcaster.value }
    public var entitlementStream: AsyncStream<Entitlements> { broadcaster.stream() }

    /// Safe to call more than once; later calls do nothing.
    public func start() {
        lock.withLock {
            guard updatesTask == nil else { return }
            updatesTask = Task { [weak self] in
                await self?.refresh()
                for await update in Transaction.updates {
                    await self?.handle(update)
                }
            }
        }
    }

    public func products(ids: [String]) async throws(TitanError) -> [StoreProduct] {
        let products: [Product]
        do {
            products = try await Product.products(for: ids)
        } catch {
            throw Self.titanError(for: error)
        }
        lock.withLock {
            for product in products { loadedProducts[product.id] = product }
        }
        // Keep the order the app asked for; StoreKit returns them in any order.
        return ids.compactMap { id in products.first { $0.id == id }.map(Self.storeProduct) }
    }

    public func purchase(_ productId: String) async throws(TitanError) -> PurchaseResult {
        let product = try await product(for: productId)
        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw Self.titanError(for: error)
        }
        switch result {
        case let .success(verification):
            guard case let .verified(transaction) = verification else {
                logger?.error("Unverified purchase of \(productId)")
                throw .unknown("unverified transaction")
            }
            await refresh()
            await transaction.finish()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    public func restore() async throws(TitanError) -> Entitlements {
        do {
            try await AppStore.sync()
        } catch {
            throw Self.titanError(for: error)
        }
        await refresh()
        return entitlements
    }

    // MARK: - Private

    private func product(for id: String) async throws(TitanError) -> Product {
        if let product = lock.withLock({ loadedProducts[id] }) { return product }
        _ = try await products(ids: [id])
        guard let product = lock.withLock({ loadedProducts[id] }) else { throw .notFound }
        return product
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = update else {
            logger?.error("Ignored an unverified transaction update")
            return
        }
        await refresh()
        await transaction.finish()
    }

    /// Recomputes entitlements from everything the user currently owns.
    private func refresh() async {
        var owned: [OwnedProduct] = []
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            owned.append(OwnedProduct(
                productId: transaction.productID,
                expirationDate: transaction.expirationDate,
                revocationDate: transaction.revocationDate
            ))
        }
        let entitlements = Self.entitlements(from: owned, config: config, now: Date())
        cache.save(entitlements)
        broadcaster.send(entitlements)
    }

    // MARK: - Mapping, kept free of StoreKit types where possible so tests can reach it

    /// The parts of a transaction that decide what the user owns.
    struct OwnedProduct: Equatable {
        var productId: String
        var expirationDate: Date?
        var revocationDate: Date?
    }

    static func entitlements(from owned: [OwnedProduct], config: PurchaseConfig, now: Date) -> Entitlements {
        let active = owned.filter { item in
            item.revocationDate == nil && (item.expirationDate.map { $0 > now } ?? true)
        }
        let premium = active.filter { config.premiumProductIds.contains($0.productId) }
        // A lifetime purchase never expires, so it wins over any subscription date.
        let expiresAt: Date? = premium.contains { $0.expirationDate == nil }
            ? nil
            : premium.compactMap(\.expirationDate).max()
        return Entitlements(
            isPremium: !premium.isEmpty,
            activeProductIds: Set(active.map(\.productId)),
            expiresAt: expiresAt
        )
    }

    static func titanError(for error: Error) -> TitanError {
        if let error = error as? StoreKitError {
            switch error {
            case .userCancelled: return .cancelled
            case .networkError: return .network(.offline)
            default: return .unknown(String(describing: error))
            }
        }
        if let error = error as? Product.PurchaseError {
            return .unknown(String(describing: error))
        }
        return .unknown(error.localizedDescription)
    }

    static func period(_ unit: Product.SubscriptionPeriod.Unit) -> StoreProduct.Period {
        switch unit {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        @unknown default: return .month
        }
    }

    static func days(in period: Product.SubscriptionPeriod) -> Int {
        let unitDays = switch period.unit {
        case .day: 1
        case .week: 7
        case .month: 30
        case .year: 365
        @unknown default: 30
        }
        return unitDays * period.value
    }

    private static func storeProduct(_ product: Product) -> StoreProduct {
        let kind: StoreProduct.Kind = switch product.type {
        case .consumable: .consumable
        case .nonConsumable: .nonConsumable
        case .autoRenewable: .autoRenewable
        default: .nonRenewable
        }
        let trial = product.subscription?.introductoryOffer.flatMap { offer in
            offer.paymentMode == .freeTrial ? days(in: offer.period) * offer.periodCount : nil
        }
        return StoreProduct(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            price: product.price,
            kind: kind,
            subscriptionPeriod: product.subscription.map { period($0.subscriptionPeriod.unit) },
            freeTrialDays: trial
        )
    }
}
