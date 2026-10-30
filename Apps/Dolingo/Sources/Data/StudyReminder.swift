import Foundation
import TitanFeatures
import TitanLocalization
import TitanPush
import TitanStorage

/// The daily study reminder chosen at sign-up or on the Notification screen.
struct ReminderSettings: Codable, Equatable, Sendable {
    var isOn = false
    var hour = 20
    var minute = 0
    /// False until the learner (or the sign-up answer) set it, so sign-up applies only once.
    var isConfigured = false
}

/// Keeps the daily reminder notification in step with the learner's settings.
@MainActor
final class StudyReminder: ObservableObject {
    static let id = "dolingo.dailyReminder"

    @Published private(set) var settings: ReminderSettings
    /// Notifications are off for Dolingo in iOS Settings.
    @Published private(set) var isDenied = false

    private let scheduler: any ReminderScheduler
    private let preferences: Preferences

    init(scheduler: any ReminderScheduler, preferences: Preferences) {
        self.scheduler = scheduler
        self.preferences = preferences
        settings = preferences.value(DolingoKeys.reminder)
    }

    /// Turns the reminder on at the time picked in the questionnaire, the first time only.
    func applySurveyChoice(_ answers: [String: SurveyAnswer], locale: Locale) async {
        guard !settings.isConfigured,
              case let .time(hour, minute)? = answers[DolingoSurvey.Step.reminder] else { return }
        settings.hour = hour
        settings.minute = minute
        await setEnabled(true, locale: locale)
    }

    func setEnabled(_ isOn: Bool, locale: Locale) async {
        settings.isOn = isOn
        settings.isConfigured = true
        await apply(locale: locale)
    }

    func setTime(hour: Int, minute: Int, locale: Locale) async {
        settings.hour = hour
        settings.minute = minute
        settings.isConfigured = true
        await apply(locale: locale)
    }

    private func apply(locale: Locale) async {
        if settings.isOn {
            if await scheduler.requestAuthorization() {
                isDenied = false
                try? await scheduler.scheduleDaily(
                    id: Self.id, hour: settings.hour, minute: settings.minute,
                    title: KitStrings.string("reminder.title", locale: locale),
                    body: KitStrings.string("reminder.body", locale: locale)
                )
            } else {
                isDenied = true
                settings.isOn = false
                await scheduler.cancel(id: Self.id)
            }
        } else {
            await scheduler.cancel(id: Self.id)
        }
        preferences.set(settings, for: DolingoKeys.reminder)
    }
}
