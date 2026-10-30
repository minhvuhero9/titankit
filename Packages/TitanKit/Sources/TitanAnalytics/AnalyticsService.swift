import Foundation

/// Product analytics without the vendor SDK.
public protocol AnalyticsService: Sendable {
    func track(_ event: AnalyticsEvent)
    func screen(_ name: String)
    func setUserId(_ id: String?)
    func setUserProperty(_ value: String?, for key: String)
    /// Off when the user opts out in Settings: nothing is sent until it is turned on again.
    func setCollectionEnabled(_ enabled: Bool)
}

/// Crash and error reports without the vendor SDK.
public protocol CrashService: Sendable {
    /// An error the app handled but wants to know about.
    func record(_ error: any Error, context: [String: String])
    /// A breadcrumb shown with the next crash report.
    func log(_ message: String)
    func setUserId(_ id: String?)
    func setCollectionEnabled(_ enabled: Bool)
}

/// Sends every call to each service, e.g. Firebase plus the console in Debug.
public struct CompositeAnalyticsService: AnalyticsService {
    private let services: [any AnalyticsService]

    public init(_ services: [any AnalyticsService]) {
        self.services = services
    }

    public func track(_ event: AnalyticsEvent) { services.forEach { $0.track(event) } }
    public func screen(_ name: String) { services.forEach { $0.screen(name) } }
    public func setUserId(_ id: String?) { services.forEach { $0.setUserId(id) } }
    public func setUserProperty(_ value: String?, for key: String) {
        services.forEach { $0.setUserProperty(value, for: key) }
    }
    public func setCollectionEnabled(_ enabled: Bool) { services.forEach { $0.setCollectionEnabled(enabled) } }
}

/// Does nothing: previews, and apps without analytics.
public struct NoOpAnalyticsService: AnalyticsService, CrashService {
    public init() {}

    public func track(_ event: AnalyticsEvent) {}
    public func screen(_ name: String) {}
    public func setUserId(_ id: String?) {}
    public func setUserProperty(_ value: String?, for key: String) {}
    public func setCollectionEnabled(_ enabled: Bool) {}
    public func record(_ error: any Error, context: [String: String]) {}
    public func log(_ message: String) {}
}
