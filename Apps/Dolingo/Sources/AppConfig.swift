import Foundation
import TitanCore
import TitanFeatures

/// Values that differ per environment. They come from Config/*.xcconfig via Info.plist.
struct AppConfig: Equatable, Sendable {
    let environment: AppEnvironment
    let apiBaseURL: URL
    /// CFBundleShortVersionString, compared with `minimum_version` at launch.
    var appVersion = "0.0.0"

    static let current = AppConfig(infoDictionary: Bundle.main.infoDictionary ?? [:])

    static let languages = ["vi", "en"]
    static let defaultLanguage = "vi"
    /// Custom URL scheme for deep links, registered in Project.swift.
    static let urlScheme = "dolingo"
    /// Placeholders until the real Privacy Policy and Terms pages are published.
    static let privacyURL = URL(string: "https://www.example.com/privacy")!
    static let termsURL = URL(string: "https://www.example.com/terms")!
    /// Placeholder until the app is registered on App Store Connect.
    static let appStoreID = "0000000000"
    /// Opened by the force update screen.
    static let appStoreURL = AppStoreLink.app(id: appStoreID)!
    /// Opened by the "Rate the app" row in Settings.
    static let writeReviewURL = AppStoreLink.writeReview(id: appStoreID)!

    init(environment: AppEnvironment, apiBaseURL: URL) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL
    }

    /// Falls back to dev so a misconfigured build never talks to production.
    init(infoDictionary: [String: Any]) {
        let rawURL = infoDictionary["TitanAPIBaseURL"] as? String ?? ""
        let fallbackURL = URL(string: "https://api-dev.example.com")!
        self.init(
            environment: AppEnvironment(infoDictionary: infoDictionary),
            apiBaseURL: URL(string: rawURL) ?? fallbackURL
        )
        appVersion = infoDictionary["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}
