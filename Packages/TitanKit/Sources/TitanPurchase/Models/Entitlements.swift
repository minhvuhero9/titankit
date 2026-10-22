import Foundation

/// What the user owns right now. StoreKit is the source of truth; the app only reads this.
public struct Entitlements: Codable, Sendable, Equatable {
    public var isPremium: Bool
    public var activeProductIds: Set<String>
    /// When the latest premium subscription runs out; nil for lifetime purchases or no premium.
    public var expiresAt: Date?

    public init(isPremium: Bool, activeProductIds: Set<String>, expiresAt: Date? = nil) {
        self.isPremium = isPremium
        self.activeProductIds = activeProductIds
        self.expiresAt = expiresAt
    }

    public static let none = Entitlements(isPremium: false, activeProductIds: [])
}

/// Which products the app sells and which of them unlock premium. Lives in the app, not the kit.
public struct PurchaseConfig: Sendable, Equatable {
    public let productIds: [String]
    public let premiumProductIds: Set<String>

    public init(productIds: [String], premiumProductIds: Set<String>) {
        self.productIds = productIds
        self.premiumProductIds = premiumProductIds
    }

    /// Every product unlocks premium, the usual case for a subscription-only app.
    public init(premiumProductIds: [String]) {
        self.init(productIds: premiumProductIds, premiumProductIds: Set(premiumProductIds))
    }
}

public enum PurchaseResult: Sendable, Equatable {
    case success
    /// Waiting for approval, e.g. Ask to Buy from a parent. Entitlements update when it goes through.
    case pending
    case cancelled
}
