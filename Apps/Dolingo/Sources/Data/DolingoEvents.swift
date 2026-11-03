import TitanAnalytics

/// Dolingo's own analytics events, on top of the kit's (`login_completed`, `paywall_viewed`...).
/// Parameters are counts, ids of bundled content and choices; never names, emails or what the
/// learner typed or said.
extension AnalyticsEvent {
    /// - Parameter accuracy: percent, nil when the lesson was done without the microphone.
    static func lessonCompleted(accuracy: Int?, minutes: Int) -> Self {
        var parameters: [String: AnalyticsValue] = ["minutes": .int(minutes)]
        if let accuracy { parameters["accuracy"] = .int(accuracy) }
        return .init("lesson_completed", parameters)
    }

    static func roleplayCompleted(tasksDone: Int, tasksTotal: Int) -> Self {
        .init("roleplay_completed", ["tasks_done": .int(tasksDone), "tasks_total": .int(tasksTotal)])
    }

    /// A badge on My Progress, by its `Achievement` raw value, e.g. `streakMaster`.
    static func badgeEarned(_ badge: String) -> Self {
        .init("badge_earned", ["badge": .string(badge)])
    }

    /// One question to "Chat with Dolingo"; the text itself is not sent.
    static let tutorMessageSent = AnalyticsEvent("tutor_message_sent")

    /// After buying or restoring Premium on the paywall.
    static let premiumUnlocked = AnalyticsEvent("premium_unlocked")

    /// Every event Dolingo sends besides the kit's, for the naming test.
    static var dolingoSamples: [AnalyticsEvent] {
        [
            .lessonCompleted(accuracy: 92, minutes: 4), .roleplayCompleted(tasksDone: 2, tasksTotal: 3),
            .badgeEarned("streakMaster"), .tutorMessageSent, .premiumUnlocked,
        ]
    }
}
