import Foundation

/// What the app shows after the splash.
public enum LaunchStatus: Equatable, Sendable {
    case ok
    /// `message` is empty when the backend sets none; the screen then uses the kit's text.
    case maintenance(message: String)
    case forceUpdate(storeURL: URL)
}

/// Decides at launch whether the app is under maintenance or too old to use.
///
///     let checker = LaunchChecker(config: remoteConfig, appVersion: "1.0.0", storeURL: AppConfig.appStoreURL)
///     switch await checker.check() { ... }
///
/// The check never blocks the app: when the fetch fails or takes longer than `timeout`,
/// it decides from the values already active (cached or default), which is `.ok` by default.
public struct LaunchChecker: Sendable {
    private let config: any RemoteConfigService
    private let appVersion: String
    private let storeURL: URL
    private let timeout: Duration

    public init(config: any RemoteConfigService, appVersion: String, storeURL: URL, timeout: Duration = .seconds(3)) {
        self.config = config
        self.appVersion = appVersion
        self.storeURL = storeURL
        self.timeout = timeout
    }

    public func check() async -> LaunchStatus {
        let config = config
        let timeout = timeout
        await withTaskGroup(of: Void.self) { group in
            group.addTask { try? await config.fetchAndActivate() }
            group.addTask { try? await Task.sleep(for: timeout) }
            _ = await group.next()
            group.cancelAll()
        }
        return Self.status(
            maintenance: config.value(for: .maintenanceEnabled),
            message: config.value(for: .maintenanceMessage),
            minimumVersion: config.value(for: .minimumVersion),
            appVersion: appVersion,
            storeURL: storeURL
        )
    }

    /// Maintenance wins over an update. An unreadable version never forces an update.
    public static func status(
        maintenance: Bool,
        message: String,
        minimumVersion: String,
        appVersion: String,
        storeURL: URL
    ) -> LaunchStatus {
        if maintenance { return .maintenance(message: message) }
        if let minimum = AppVersion(minimumVersion), let current = AppVersion(appVersion), current < minimum {
            return .forceUpdate(storeURL: storeURL)
        }
        return .ok
    }
}
