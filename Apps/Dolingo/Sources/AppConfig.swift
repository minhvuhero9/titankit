import Foundation

/// Values that differ per environment. They come from Config/*.xcconfig via Info.plist.
struct AppConfig: Equatable, Sendable {
    enum Environment: String, Sendable {
        case dev, staging, prod
    }

    let environment: Environment
    let apiBaseURL: URL

    static let current = AppConfig(infoDictionary: Bundle.main.infoDictionary ?? [:])

    init(environment: Environment, apiBaseURL: URL) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL
    }

    /// Falls back to dev so a misconfigured build never talks to production.
    init(infoDictionary: [String: Any]) {
        let rawEnvironment = infoDictionary["TitanAppEnvironment"] as? String ?? ""
        let rawURL = infoDictionary["TitanAPIBaseURL"] as? String ?? ""
        let environment = Environment(rawValue: rawEnvironment) ?? .dev
        let fallbackURL = URL(string: "https://api-dev.example.com")!
        self.init(environment: environment, apiBaseURL: URL(string: rawURL) ?? fallbackURL)
    }
}
