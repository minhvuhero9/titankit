import Foundation
import TitanSpeech
import TitanStorage

/// Everything My Progress shows, counted on the device and saved in Preferences.
struct ActivityStats: Codable, Equatable, Sendable {
    /// Seconds spent learning, by day ("2026-10-29").
    var secondsByDay: [String: Int] = [:]
    var lessonsPassed = 0
    /// Lessons finished with 90 % accuracy or more.
    var perfectLessons = 0
    /// Phrases said well enough to pass, and the words in them.
    var sentencesSpoken = 0
    var wordsSpoken = 0
    var perfectPhrases = 0
    /// Every scored attempt, for the average pronunciation.
    var scoredAttempts = 0
    var scoreTotal = 0.0
    var audioListened = 0
    var roleplaysFinished = 0
    var roleplayTasksDone = 0
    var roleplayTasksTotal = 0
    /// Phrasebook phrases said well at least once.
    var practisedPhrases: Set<String> = []
    /// When each badge was earned.
    var badges: [String: Date] = [:]
}

/// Badges of the Achievements tab, in display order, with the rule that earns each.
enum Achievement: String, CaseIterable, Sendable, Identifiable {
    case risingStar, quickLearner, milestoneMaster, persistentLearner, streakMaster
    case roleplayHero, conversationChampion, pronunciationPro, fluencyFanatic, listeningLegend

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .risingStar: "🏅"
        case .quickLearner: "🏆"
        case .milestoneMaster: "🎖️"
        case .persistentLearner: "🔥"
        case .streakMaster: "⚡️"
        case .roleplayHero: "🎭"
        case .conversationChampion: "💬"
        case .pronunciationPro: "🎙️"
        case .fluencyFanatic: "🚀"
        case .listeningLegend: "🎧"
        }
    }

    func isEarned(_ stats: ActivityStats, chaptersDone: Int, streak: Int) -> Bool {
        switch self {
        case .risingStar: stats.lessonsPassed >= 1
        case .quickLearner: stats.lessonsPassed >= 5
        case .milestoneMaster: chaptersDone >= 1
        case .persistentLearner: streak >= 3
        case .streakMaster: streak >= 7
        case .roleplayHero: stats.roleplaysFinished >= 1
        case .conversationChampion: stats.roleplaysFinished >= 5
        case .pronunciationPro: stats.perfectPhrases >= 20
        case .fluencyFanatic: stats.sentencesSpoken >= 50
        case .listeningLegend: stats.audioListened >= 100
        }
    }
}

/// A moment worth a full-screen congratulation after an activity.
enum Celebration: Equatable, Sendable, Identifiable {
    /// The first activity of the day, with the days learned this week (Monday first).
    case streak(days: Int, week: [Bool])
    case badge(Achievement)

    var id: String {
        switch self {
        case let .streak(days, _): "streak.\(days)"
        case let .badge(badge): "badge.\(badge.rawValue)"
        }
    }
}

/// Records what the learner does and works out streaks, badges and celebrations.
@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var stats: ActivityStats
    /// Shown one by one over the app, then removed with `dismissCelebration()`.
    @Published private(set) var celebrations: [Celebration] = []

    private let preferences: Preferences
    private let calendar: Calendar
    private let now: () -> Date
    /// Chapters of the course finished, read when checking badges.
    var chaptersDone: @MainActor () -> Int = { 0 }

    init(preferences: Preferences, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.preferences = preferences
        self.calendar = calendar
        self.now = now
        stats = preferences.value(DolingoKeys.activity)
    }

    // MARK: - Recording

    func recordSpoken(_ score: PronunciationScore, phraseId: String? = nil) {
        update { stats in
            stats.scoredAttempts += 1
            stats.scoreTotal += score.value
            guard score.verdict.isPass else { return }
            stats.sentencesSpoken += 1
            stats.wordsSpoken += score.words.filter(\.isMatched).count
            if score.verdict == .perfect { stats.perfectPhrases += 1 }
            if let phraseId { stats.practisedPhrases.insert(phraseId) }
        }
    }

    func recordListened() {
        update { $0.audioListened += 1 }
    }

    /// - Parameter accuracy: nil when the lesson was done without the microphone.
    func recordLesson(accuracy: Double?, seconds: TimeInterval) {
        addTime(seconds)
        update { stats in
            stats.lessonsPassed += 1
            if (accuracy ?? 0) >= 0.9 { stats.perfectLessons += 1 }
        }
    }

    func recordRoleplay(tasksDone: Int, tasksTotal: Int, seconds: TimeInterval) {
        addTime(seconds)
        update { stats in
            stats.roleplaysFinished += 1
            stats.roleplayTasksDone += tasksDone
            stats.roleplayTasksTotal += tasksTotal
        }
    }

    /// Time spent practising phrases on the Speak tab.
    func recordPractice(seconds: TimeInterval) {
        addTime(seconds)
    }

    func dismissCelebration() {
        if !celebrations.isEmpty { celebrations.removeFirst() }
    }

    // MARK: - Reading

    /// Days learned in a row, ending today, or yesterday when nothing is done yet today.
    var currentStreak: Int {
        Self.currentStreak(days: learnedDays, today: now(), calendar: calendar)
    }

    var longestStreak: Int {
        Self.longestStreak(days: learnedDays, calendar: calendar)
    }

    var learningDays: Int { learnedDays.count }

    func learned(on date: Date) -> Bool {
        (stats.secondsByDay[dayKey(date)] ?? 0) > 0
    }

    func minutes(on date: Date) -> Int {
        Int(((Double(stats.secondsByDay[dayKey(date)] ?? 0)) / 60).rounded())
    }

    /// Average score of every spoken attempt, from 0 to 1.
    var pronunciation: Double {
        stats.scoredAttempts == 0 ? 0 : stats.scoreTotal / Double(stats.scoredAttempts)
    }

    var roleplayTaskRate: Double {
        stats.roleplayTasksTotal == 0 ? 0 : Double(stats.roleplayTasksDone) / Double(stats.roleplayTasksTotal)
    }

    /// Share of the last 30 days with some learning.
    var regularity: Double {
        let today = calendar.startOfDay(for: now())
        let days = (0..<30).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        return Double(days.filter(learned(on:)).count) / 30
    }

    /// Monday to Sunday of the current week, true on days with learning.
    var thisWeek: [Bool] {
        var monday = calendar
        monday.firstWeekday = 2
        guard let interval = monday.dateInterval(of: .weekOfYear, for: now()) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }.map(learned(on:))
    }

    func earnedDate(_ badge: Achievement) -> Date? {
        stats.badges[badge.rawValue]
    }

    // MARK: - Private

    private var learnedDays: Set<String> {
        Set(stats.secondsByDay.filter { $0.value > 0 }.keys)
    }

    private func addTime(_ seconds: TimeInterval) {
        let today = dayKey(now())
        let isFirstToday = (stats.secondsByDay[today] ?? 0) == 0
        let firstNew = celebrations.count
        update { $0.secondsByDay[today, default: 0] += max(1, Int(seconds.rounded())) }
        // The streak shows before any badge the same activity earned.
        if isFirstToday {
            celebrations.insert(.streak(days: currentStreak, week: thisWeek), at: firstNew)
        }
    }

    private func update(_ change: (inout ActivityStats) -> Void) {
        change(&stats)
        let streak = currentStreak
        for badge in Achievement.allCases where stats.badges[badge.rawValue] == nil {
            if badge.isEarned(stats, chaptersDone: chaptersDone(), streak: streak) {
                stats.badges[badge.rawValue] = now()
                celebrations.append(.badge(badge))
            }
        }
        preferences.set(stats, for: DolingoKeys.activity)
    }

    private func dayKey(_ date: Date) -> String {
        Self.dayKey(date, calendar: calendar)
    }

    nonisolated static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    nonisolated static func currentStreak(days: Set<String>, today: Date, calendar: Calendar) -> Int {
        var day = calendar.startOfDay(for: today)
        if !days.contains(dayKey(day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while days.contains(dayKey(day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    nonisolated static func longestStreak(days: Set<String>, calendar: Calendar) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = days.compactMap(formatter.date(from:)).sorted()
        var longest = 0, run = 0
        var previous: Date?
        for date in dates {
            if let previous, calendar.dateComponents([.day], from: previous, to: date).day == 1 {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = date
        }
        return longest
    }
}
