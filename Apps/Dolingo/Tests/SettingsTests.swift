import XCTest
import TitanFeatures
import TitanLocalization
import TitanPush
import TitanStorage
@testable import Dolingo

@MainActor
final class SettingsTests: XCTestCase {
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "SettingsTests")!
        defaults.removePersistentDomain(forName: "SettingsTests")
        return Preferences(defaults: defaults)
    }

    private let vietnamese = Locale(identifier: "vi")

    func testSurveyTimeTurnsTheReminderOnOnce() async {
        let scheduler = MockReminderScheduler()
        let preferences = makePreferences()
        let reminder = StudyReminder(scheduler: scheduler, preferences: preferences)
        let answers: [String: SurveyAnswer] = [DolingoSurvey.Step.reminder: .time(hour: 7, minute: 30)]
        await reminder.applySurveyChoice(answers, locale: vietnamese)
        XCTAssertEqual(scheduler.reminders[StudyReminder.id]?.hour, 7)
        XCTAssertEqual(scheduler.reminders[StudyReminder.id]?.minute, 30)
        XCTAssertNotEqual(scheduler.reminders[StudyReminder.id]?.title, "reminder.title", "the title is translated")

        await reminder.setEnabled(false, locale: vietnamese)
        XCTAssertNil(scheduler.reminders[StudyReminder.id])
        await reminder.applySurveyChoice(answers, locale: vietnamese)
        XCTAssertNil(scheduler.reminders[StudyReminder.id], "a choice made in Settings wins over sign-up")
        XCTAssertFalse(StudyReminder(scheduler: scheduler, preferences: preferences).settings.isOn)
    }

    func testChangingTheTimeReschedules() async {
        let scheduler = MockReminderScheduler()
        let reminder = StudyReminder(scheduler: scheduler, preferences: makePreferences())
        await reminder.setEnabled(true, locale: vietnamese)
        await reminder.setTime(hour: 21, minute: 15, locale: vietnamese)
        XCTAssertEqual(scheduler.reminders[StudyReminder.id], MockReminderScheduler.Reminder(
            hour: 21, minute: 15,
            title: KitStrings.string("reminder.title", locale: vietnamese),
            body: KitStrings.string("reminder.body", locale: vietnamese)
        ))
    }

    func testRefusedNotificationsTurnTheReminderOff() async {
        let reminder = StudyReminder(scheduler: MockReminderScheduler(isAuthorized: false), preferences: makePreferences())
        await reminder.setEnabled(true, locale: vietnamese)
        XCTAssertTrue(reminder.isDenied)
        XCTAssertFalse(reminder.settings.isOn)
    }

    func testRestartClearsLessonsAndActivity() async {
        let preferences = makePreferences()
        let learning = LearningStore(repository: BundledCourseRepository(), preferences: preferences)
        await learning.load()
        let course = try? XCTUnwrap(learning.course.value.flatMap { $0 })
        if let first = course?.lessons.first { learning.complete(first) }
        let activity = ActivityStore(preferences: preferences)
        activity.recordLesson(accuracy: 1, seconds: 60)
        learning.reset()
        activity.reset()
        XCTAssertTrue(learning.progress.completedLessons.isEmpty)
        XCTAssertEqual(activity.stats, ActivityStats())
        XCTAssertTrue(activity.celebrations.isEmpty)
    }

    func testEveryFAQEntryHasBothLanguages() {
        for entry in FAQScreen.entries {
            for code in AppConfig.languages {
                for key in ["faq.\(entry.id).q", "faq.\(entry.id).a"] {
                    XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
                }
            }
        }
        XCTAssertEqual(Set(FAQScreen.entries.map(\.id)).count, FAQScreen.entries.count)
    }
}
