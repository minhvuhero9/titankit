import FirebaseRemoteConfig
import Foundation
import TitanCore
import TitanRemoteConfig

/// `RemoteConfigService` on Firebase Remote Config. Values come back as strings, which every
/// `RemoteConfigKey` type knows how to read; a key missing on the server gives its default.
public struct FirebaseRemoteConfigService: RemoteConfigService {
    /// - Parameter minimumFetchInterval: seconds between two downloads; 0 while developing.
    public init(minimumFetchInterval: TimeInterval = 3600) {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = minimumFetchInterval
        RemoteConfig.remoteConfig().configSettings = settings
    }

    public func fetchAndActivate() async throws(TitanError) {
        do {
            _ = try await RemoteConfig.remoteConfig().fetchAndActivate()
        } catch {
            throw .network(.server(statusCode: (error as NSError).code))
        }
    }

    public func raw(for name: String) -> RemoteConfigRaw? {
        let value = RemoteConfig.remoteConfig().configValue(forKey: name)
        guard value.source != .static else { return nil }
        return .string(value.stringValue)
    }
}
