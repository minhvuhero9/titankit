import Foundation

/// What the paywall sells. Product ids live in the app (`AppConfig`), never in the kit.
///
///     PaywallConfig(productIds: AppConfig.purchase.productIds,
///                   highlightedProductId: "com.titanstudio.dolingo.premium.yearly",
///                   termsURL: AppConfig.termsURL, privacyURL: AppConfig.privacyURL)
public struct PaywallConfig: Sendable, Equatable {
    /// Shown in this order, one plan card each.
    public var productIds: [String]
    /// Gets the "Most popular" badge.
    public var highlightedProductId: String?
    /// App Review asks for links to the Terms of Use (EULA) and the Privacy Policy on the paywall.
    public var termsURL: URL
    public var privacyURL: URL

    public init(productIds: [String], highlightedProductId: String? = nil, termsURL: URL, privacyURL: URL) {
        self.productIds = productIds
        self.highlightedProductId = highlightedProductId
        self.termsURL = termsURL
        self.privacyURL = privacyURL
    }
}
