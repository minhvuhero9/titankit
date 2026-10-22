import Foundation
import TitanCore

/// Remote config for tests, previews and the app until the Firebase adapter is wired in.
///
///     let config = MockRemoteConfig(values: ["maintenance_enabled": .bool(true)])
public final class MockRemoteConfig: RemoteConfigService, @unchecked Sendable {
    // @unchecked: all state is guarded by `lock`.
    private let lock = NSLock()
    private var values: [String: RemoteConfigRaw]
    private var fetchError: TitanError?
    private let fetchDelay: Duration
    private var fetchCount = 0

    /// - Parameters:
    ///   - fetchError: thrown by every `fetchAndActivate()` until changed.
    ///   - fetchDelay: how long a fetch takes, to test timeouts.
    public init(values: [String: RemoteConfigRaw] = [:], fetchError: TitanError? = nil, fetchDelay: Duration = .zero) {
        self.values = values
        self.fetchError = fetchError
        self.fetchDelay = fetchDelay
    }

    public func fetchAndActivate() async throws(TitanError) {
        lock.withLock { fetchCount += 1 }
        if fetchDelay > .zero {
            do { try await Task.sleep(for: fetchDelay) } catch { throw .cancelled }
        }
        if let error = lock.withLock({ fetchError }) { throw error }
    }

    public func raw(for name: String) -> RemoteConfigRaw? {
        lock.withLock { values[name] }
    }

    public func set(_ raw: RemoteConfigRaw?, for name: String) {
        lock.withLock { values[name] = raw }
    }

    public func failFetches(with error: TitanError?) {
        lock.withLock { fetchError = error }
    }

    public var fetches: Int {
        lock.withLock { fetchCount }
    }
}
