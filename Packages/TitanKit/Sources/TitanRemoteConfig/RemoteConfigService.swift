import TitanCore

/// Remote config without the vendor SDK. The Firebase adapter and `MockRemoteConfig` implement it.
public protocol RemoteConfigService: Sendable {
    /// Downloads the latest values and makes them the ones `value(for:)` returns.
    func fetchAndActivate() async throws(TitanError)
    /// The active value stored under `name`, or nil when the backend has none.
    func raw(for name: String) -> RemoteConfigRaw?
}

public extension RemoteConfigService {
    /// Never fails: a missing or unreadable value gives the key's default.
    func value<Value>(for key: RemoteConfigKey<Value>) -> Value {
        raw(for: key.name).flatMap(Value.decode) ?? key.defaultValue
    }
}
