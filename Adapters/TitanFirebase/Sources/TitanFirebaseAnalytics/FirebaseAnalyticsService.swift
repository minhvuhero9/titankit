import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation
import TitanAnalytics

/// `AnalyticsService` on Google Analytics for Firebase. Each environment has its own Firebase
/// project, so Dev and Staging events never mix with Prod.
public struct FirebaseAnalyticsService: AnalyticsService {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters.mapValues(Self.value))
    }

    public func screen(_ name: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: name])
    }

    public func setUserId(_ id: String?) {
        Analytics.setUserID(id)
    }

    public func setUserProperty(_ value: String?, for key: String) {
        Analytics.setUserProperty(value, forName: key)
    }

    public func setCollectionEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }

    static func value(_ value: AnalyticsValue) -> Any {
        switch value {
        case let .string(text): text
        case let .int(number): number
        case let .double(number): number
        // Firebase has no boolean parameters.
        case let .bool(flag): flag ? 1 : 0
        }
    }
}

/// `CrashService` on Firebase Crashlytics.
public struct CrashlyticsService: CrashService {
    public init() {}

    public func record(_ error: any Error, context: [String: String]) {
        Crashlytics.crashlytics().record(error: error, userInfo: context)
    }

    public func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    public func setUserId(_ id: String?) {
        Crashlytics.crashlytics().setUserID(id ?? "")
    }

    public func setCollectionEnabled(_ enabled: Bool) {
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }
}
