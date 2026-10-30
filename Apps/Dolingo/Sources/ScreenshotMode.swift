import Foundation
import TitanAI
import TitanAnalytics
import TitanAuth
import TitanPurchase
import TitanPush
import TitanRemoteConfig
import TitanSpeech
import TitanStorage

/// The App Store screenshots: launched by `DolingoUITests` with `-screenshots <screen>
/// -screenshotLanguage vi`, the app starts signed in as a learner a few lessons in, on mock
/// services (no network, no permission prompts), and opens on that screen. Nothing it writes
/// touches the real app's data.
enum ScreenshotMode {
    enum Screen: String, CaseIterable, Sendable {
        case home, lesson, chats, tutor, speak, progress, paywall
    }

    /// The screen to show when launched with `-screenshots <screen>`.
    static func screen(in arguments: [String]) -> Screen? {
        value(after: "-screenshots", in: arguments).flatMap(Screen.init)
    }

    static func language(in arguments: [String]) -> String {
        let language = value(after: "-screenshotLanguage", in: arguments) ?? AppConfig.defaultLanguage
        return AppConfig.languages.contains(language) ? language : AppConfig.defaultLanguage
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    static let suiteName = "com.titanstudio.dolingo.screenshots"

    @MainActor
    static func container(for screen: Screen, language: String) -> AppContainer {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(language, forKey: "titan.language")
        let preferences = Preferences(defaults: defaults)
        seed(preferences, language: language)

        let learner = AuthUser(id: "screenshots", email: "minh@dolingo.app", displayName: "Minh", provider: .email)
        let container = AppContainer(
            config: .current,
            preferences: preferences,
            languageDefaults: defaults,
            auth: MockAuthService(signedIn: learner),
            remoteConfig: MockRemoteConfig(),
            purchase: MockPurchaseService(),
            reminders: MockReminderScheduler(),
            speech: MockSpeechRecognizer(transcripts: ["Nice to meet you"]),
            chat: MockChatService(),
            analytics: NoOpAnalyticsService(),
            roleplayAI: MockRoleplayAI()
        )
        open(screen, in: container)
        return container
    }

    @MainActor
    private static func open(_ screen: Screen, in container: AppContainer) {
        let tabs = container.tabs
        switch screen {
        case .home: tabs.selected = .home
        case .lesson: tabs.router(for: .home).present(.lesson(id: "en.basics.family"), fullScreen: true)
        case .chats: tabs.selected = .chats
        case .tutor:
            tabs.selected = .chats
            tabs.router(for: .chats).present(.tutorChat, fullScreen: true)
        case .speak: tabs.selected = .speak
        case .progress: tabs.selected = .progress
        case .paywall: tabs.router(for: .home).present(.paywall)
        }
    }

    /// A learner one week in: three lessons done, a seven-day streak, some phrases saved.
    private static func seed(_ preferences: Preferences, language: String) {
        preferences.set(true, for: DolingoKeys.hasSeenOnboarding)
        preferences.set(LearningProgress(completedLessons: [
            "en.basics.greetings", "en.basics.introductions", "en.basics.numbers",
        ]), for: DolingoKeys.learningProgress)

        let calendar = Calendar.current
        var stats = ActivityStats()
        let minutes = [12, 18, 9, 25, 15, 20, 14]
        for (offset, minutes) in minutes.enumerated() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            stats.secondsByDay[ActivityStore.dayKey(day, calendar: calendar)] = minutes * 60
        }
        stats.lessonsPassed = 3
        stats.perfectLessons = 2
        stats.sentencesSpoken = 46
        stats.wordsSpoken = 212
        stats.perfectPhrases = 18
        stats.scoredAttempts = 52
        stats.scoreTotal = 52 * 0.87
        stats.audioListened = 64
        stats.roleplaysFinished = 2
        stats.roleplayTasksDone = 5
        stats.roleplayTasksTotal = 6
        let earned = Date().addingTimeInterval(-2 * 24 * 3600)
        for badge in [Achievement.risingStar, .quickLearner, .persistentLearner, .streakMaster] {
            stats.badges[badge.rawValue] = earned
        }
        preferences.set(stats, for: DolingoKeys.activity)
        preferences.set(tutorConversation(language), for: DolingoKeys.tutorChat)
    }

    private static func tutorConversation(_ language: String) -> [ChatMessage] {
        if language == "en" {
            return [
                ChatMessage(role: .user, text: "How do I order a coffee politely?"),
                ChatMessage(role: .assistant, text: "Try: \"Could I have a latte, please?\" \"Could I…\" sounds polite and friendly. "
                    + "Want to practise? I'm the barista: \"Hi! What can I get for you?\""),
                ChatMessage(role: .user, text: "Could I have a latte, please?"),
                ChatMessage(role: .assistant, text: "Perfect! 🎉 \"Sure! What size would you like: small, medium or large?\""),
            ]
        }
        return [
            ChatMessage(role: .user, text: "Gọi cà phê sao cho lịch sự nhỉ?"),
            ChatMessage(role: .assistant, text: "Bạn thử nói: \"Could I have a latte, please?\" Mẫu \"Could I…\" nghe lịch sự và thân thiện. "
                + "Mình đóng vai nhân viên nhé: \"Hi! What can I get for you?\""),
            ChatMessage(role: .user, text: "Could I have a latte, please?"),
            ChatMessage(role: .assistant, text: "Tuyệt vời! 🎉 \"Sure! What size would you like: small, medium or large?\""),
        ]
    }
}

extension AppContainer {
    /// The container the app starts with: the real one, or the screenshot one under UI tests.
    @MainActor
    static func launch(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainer {
        if let screen = ScreenshotMode.screen(in: arguments) {
            return ScreenshotMode.container(for: screen, language: ScreenshotMode.language(in: arguments))
        }
        return AppContainer(config: .current)
    }
}
