import Foundation

/// Remembers every call, for tests that check what was sent.
public final class SpyAnalyticsService: AnalyticsService, CrashService, @unchecked Sendable {
    // @unchecked: all state is guarded by `lock`.
    private let lock = NSLock()
    private var _events: [AnalyticsEvent] = []
    private var _screens: [String] = []
    private var _errors: [String] = []
    private var _userId: String?
    private var _properties: [String: String] = [:]
    private var _isCollectionEnabled = true

    public init() {}

    public var events: [AnalyticsEvent] { lock.withLock { _events } }
    public var screens: [String] { lock.withLock { _screens } }
    /// `String(describing:)` of each recorded error.
    public var errors: [String] { lock.withLock { _errors } }
    public var userId: String? { lock.withLock { _userId } }
    public var properties: [String: String] { lock.withLock { _properties } }
    public var isCollectionEnabled: Bool { lock.withLock { _isCollectionEnabled } }

    public func track(_ event: AnalyticsEvent) { lock.withLock { _events.append(event) } }
    public func screen(_ name: String) { lock.withLock { _screens.append(name) } }
    public func setUserId(_ id: String?) { lock.withLock { _userId = id } }
    public func setUserProperty(_ value: String?, for key: String) { lock.withLock { _properties[key] = value } }
    public func setCollectionEnabled(_ enabled: Bool) { lock.withLock { _isCollectionEnabled = enabled } }
    public func record(_ error: any Error, context: [String: String]) {
        lock.withLock { _errors.append(String(describing: error)) }
    }
    public func log(_ message: String) {}
}
