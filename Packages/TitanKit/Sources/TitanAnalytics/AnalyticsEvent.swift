import Foundation

/// A parameter value in the types every analytics backend accepts.
public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

/// Something the user did, named `object_action` in snake case: `paywall_viewed`.
///
///     analytics.track(.login(method: "apple"))
///     analytics.track(AnalyticsEvent("lesson_completed", ["accuracy": .int(92)]))
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: AnalyticsValue]

    public init(_ name: String, _ parameters: [String: AnalyticsValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }

    /// Lowercase letters, digits and "_", starting with a letter, at most 40 characters:
    /// the strictest of the backends (Firebase).
    public static func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isLowercase, first.isASCII, name.count <= 40 else { return false }
        return name.allSatisfy { ($0.isASCII && ($0.isLowercase || $0.isNumber)) || $0 == "_" }
    }
}

// Events every app made with the kit sends the same way.
public extension AnalyticsEvent {
    static func login(method: String) -> Self { .init("login_completed", ["method": .string(method)]) }
    static func signUp(method: String) -> Self { .init("sign_up_completed", ["method": .string(method)]) }
    static func paywallViewed(source: String) -> Self { .init("paywall_viewed", ["source": .string(source)]) }
    static func purchaseCompleted(productId: String) -> Self {
        .init("purchase_completed", ["product_id": .string(productId)])
    }
    static let passwordReset = AnalyticsEvent("password_reset_completed")
    static let accountDeleted = AnalyticsEvent("account_deleted")
}
