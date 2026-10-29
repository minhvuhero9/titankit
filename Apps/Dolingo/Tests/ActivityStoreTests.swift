import XCTest
import TitanSpeech
import TitanStorage
@testable import Dolingo

@MainActor
final class ActivityStoreTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }

    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "ActivityStoreTests")!
        defaults.removePersistentDomain(forName: "ActivityStoreTests")
        return Preferences(defaults: defaults)
    }

    private func day(_ value: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: value, hour: 10))!
    }

    func testFirstLessonOfTheDayCelebratesTheStreakThenTheBadge() {
        let store = ActivityStore(preferences: makePreferences(), calendar: calendar) { self.day(29) }
        store.recordLesson(accuracy: 0.95, seconds: 120)
        XCTAssertEqual(store.celebrations.map(\.id), ["streak.1", "badge.risingStar"])
        XCTAssertEqual(store.stats.lessonsPassed, 1)
        XCTAssertEqual(store.stats.perfectLessons, 1)
        XCTAssertEqual(store.minutes(on: day(29)), 2)
        XCTAssertNotNil(store.earnedDate(.risingStar))

        store.dismissCelebration()
        store.dismissCelebration()
        store.recordLesson(accuracy: 0.5, seconds: 60)
        XCTAssertTrue(store.celebrations.isEmpty, "only the first activity of the day shows the streak")
        XCTAssertEqual(store.stats.perfectLessons, 1)
    }

    func testStreaksCountDaysInARow() {
        let days: Set<String> = ["2026-10-20", "2026-10-21", "2026-10-22", "2026-10-27", "2026-10-28"]
        XCTAssertEqual(ActivityStore.currentStreak(days: days, today: day(28), calendar: calendar), 2)
        XCTAssertEqual(ActivityStore.currentStreak(days: days, today: day(29), calendar: calendar), 2, "today not done yet")
        XCTAssertEqual(ActivityStore.currentStreak(days: days, today: day(30), calendar: calendar), 0)
        XCTAssertEqual(ActivityStore.longestStreak(days: days, calendar: calendar), 3)
        XCTAssertEqual(ActivityStore.longestStreak(days: [], calendar: calendar), 0)
    }

    func testThreeDaysInARowEarnsPersistentLearner() {
        let preferences = makePreferences()
        var today = day(27)
        let store = ActivityStore(preferences: preferences, calendar: calendar) { today }
        store.recordPractice(seconds: 60)
        today = day(28)
        store.recordPractice(seconds: 60)
        today = day(29)
        store.recordPractice(seconds: 60)
        XCTAssertEqual(store.currentStreak, 3)
        XCTAssertNotNil(store.earnedDate(.persistentLearner))
        XCTAssertEqual(store.celebrations.last, .badge(.persistentLearner))
        XCTAssertEqual(ActivityStore(preferences: preferences, calendar: calendar) { today }.learningDays, 3)
    }

    func testSpokenPhrasesCountWordsAndPronunciation() {
        let store = ActivityStore(preferences: makePreferences(), calendar: calendar) { self.day(29) }
        store.recordSpoken(PronunciationScore(expected: "Nice to meet you", heard: "nice to meet you"), phraseId: "Nice to meet you")
        store.recordSpoken(PronunciationScore(expected: "Good morning", heard: "good night"))
        XCTAssertEqual(store.stats.sentencesSpoken, 1)
        XCTAssertEqual(store.stats.wordsSpoken, 4)
        XCTAssertEqual(store.stats.perfectPhrases, 1)
        XCTAssertEqual(store.stats.practisedPhrases, ["Nice to meet you"])
        XCTAssertEqual(store.pronunciation, 0.75, accuracy: 0.001)
    }

    func testRoleplaysCountTasks() {
        let store = ActivityStore(preferences: makePreferences(), calendar: calendar) { self.day(29) }
        store.recordRoleplay(tasksDone: 3, tasksTotal: 4, seconds: 200)
        XCTAssertEqual(store.stats.roleplaysFinished, 1)
        XCTAssertEqual(store.roleplayTaskRate, 0.75, accuracy: 0.001)
        XCTAssertNotNil(store.earnedDate(.roleplayHero))
        XCTAssertEqual(store.thisWeek.filter { $0 }.count, 1)
    }
}
