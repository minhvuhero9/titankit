import Foundation

/// Which backend and settings a build talks to. Set per scheme in Config/*.xcconfig.
public enum AppEnvironment: String, Sendable, CaseIterable {
    case dev, staging, prod

    /// Info.plist key filled from the APP_ENV build setting.
    public static let infoPlistKey = "TitanAppEnvironment"

    public static var current: AppEnvironment {
        AppEnvironment(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    /// Falls back to dev so a misconfigured build never talks to production.
    public init(infoDictionary: [String: Any]) {
        let raw = infoDictionary[Self.infoPlistKey] as? String ?? ""
        self = AppEnvironment(rawValue: raw) ?? .dev
    }

    public var isProduction: Bool { self == .prod }

    /// Default minimum log level for this environment.
    public var defaultLogLevel: LogLevel { isProduction ? .warning : .debug }
}
