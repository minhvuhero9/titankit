// Events, screens and crash reports behind AnalyticsService and CrashService. Vendors plug in as
// adapters (Firebase Analytics and Crashlytics in Adapters/TitanFirebase); the kit only defines
// the protocols, the event names and the in-memory versions.
public enum TitanAnalyticsModule {
    public static let moduleName = "TitanAnalytics"
}
