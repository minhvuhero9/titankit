import Foundation
import TitanAnalytics
import TitanStorage

/// Figma "settings - data & analytics": what the learner agrees to share.
struct DataSharing: Codable, Equatable, Sendable {
    /// Anonymous usage statistics (screens opened, lessons finished) that help improve Dolingo.
    var analytics = true
    /// Crash reports with the app's state at the moment of the crash.
    var crashReports = true
}

/// Saves the choices and turns collection on or off in the analytics and crash services.
@MainActor
final class DataSharingStore: ObservableObject {
    @Published var settings: DataSharing {
        didSet {
            preferences.set(settings, for: DolingoKeys.dataSharing)
            apply()
        }
    }

    private let preferences: Preferences
    private let analytics: any AnalyticsService
    private let crash: any CrashService

    init(preferences: Preferences, analytics: any AnalyticsService, crash: any CrashService) {
        self.preferences = preferences
        self.analytics = analytics
        self.crash = crash
        settings = preferences.value(DolingoKeys.dataSharing)
        apply()
    }

    private func apply() {
        analytics.setCollectionEnabled(settings.analytics)
        crash.setCollectionEnabled(settings.crashReports)
    }
}
