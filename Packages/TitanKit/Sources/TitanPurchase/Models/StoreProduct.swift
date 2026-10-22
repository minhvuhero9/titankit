import Foundation

/// A product as the kit's screens show it, whichever store sold it.
public struct StoreProduct: Sendable, Identifiable, Equatable {
    public enum Kind: Sendable, Equatable {
        case consumable, nonConsumable, autoRenewable, nonRenewable
    }

    public enum Period: Sendable, Equatable {
        case day, week, month, year
    }

    public let id: String
    public let displayName: String
    public let description: String
    /// Already formatted for the user's App Store region, e.g. "79.000 ₫".
    public let displayPrice: String
    public let price: Decimal
    public let kind: Kind
    /// nil for anything that is not a subscription.
    public let subscriptionPeriod: Period?
    /// Length of the free trial a new subscriber gets, if any.
    public let freeTrialDays: Int?

    public init(
        id: String,
        displayName: String,
        description: String = "",
        displayPrice: String,
        price: Decimal,
        kind: Kind,
        subscriptionPeriod: Period? = nil,
        freeTrialDays: Int? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.price = price
        self.kind = kind
        self.subscriptionPeriod = subscriptionPeriod
        self.freeTrialDays = freeTrialDays
    }
}
