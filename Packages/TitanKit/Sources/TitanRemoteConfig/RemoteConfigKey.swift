/// A remote config key with its type and the value used when the backend has none.
///
///     extension RemoteConfigKey where Value == Bool {
///         static var showNewHome: Self { .init("dolingo_show_new_home", default: false) }
///     }
///     if remoteConfig.value(for: .showNewHome) { ... }
public struct RemoteConfigKey<Value: RemoteConfigValue>: Sendable {
    public let name: String
    public let defaultValue: Value

    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

// Keys every app shares. App keys carry the app's prefix, e.g. "dolingo_".
public extension RemoteConfigKey where Value == Bool {
    static var maintenanceEnabled: Self { .init("maintenance_enabled", default: false) }
}

public extension RemoteConfigKey where Value == String {
    /// Shown on the maintenance screen; empty uses the kit's own message.
    static var maintenanceMessage: Self { .init("maintenance_message", default: "") }
    /// Versions below this one must update before using the app.
    static var minimumVersion: Self { .init("minimum_version", default: "0.0.0") }
}
