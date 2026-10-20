import Foundation
import TitanCore

/// Values that differ per environment. They come from Config/*.xcconfig via Info.plist.
struct AppConfig: Equatable, Sendable {
    let environment: AppEnvironment
    let apiBaseURL: URL

    static let current = AppConfig(infoDictionary: Bundle.main.infoDictionary ?? [:])

    static let languages = ["vi", "en"]
    static let defaultLanguage = "vi"
    /// Custom URL scheme for deep links, registered in Project.swift.
    static let urlScheme = "dolingo"

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
    }
}
