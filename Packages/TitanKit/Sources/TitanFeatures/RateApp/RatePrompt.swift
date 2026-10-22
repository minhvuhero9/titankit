import StoreKit
import SwiftUI

/// When the app may ask for an App Store rating. Apple shows the system prompt at most
/// three times a year anyway, so these rules decide when asking is worth one of those.
public struct RatePromptPolicy: Sendable, Equatable {
    public var minLaunches: Int
    /// Things the user did that went well, e.g. finishing a lesson.
    public var minSignificantEvents: Int
    public var minDaysSinceInstall: Int
    public var minDaysBetweenPrompts: Int
    /// Never asks twice for the same app version.
    public var oncePerVersion: Bool

    public init(
        minLaunches: Int = 3,
        minSignificantEvents: Int = 3,
        minDaysSinceInstall: Int = 3,
        minDaysBetweenPrompts: Int = 120,
        oncePerVersion: Bool = true
    ) {
        self.minLaunches = minLaunches
        self.minSignificantEvents = minSignificantEvents
        self.minDaysSinceInstall = minDaysSinceInstall
        self.minDaysBetweenPrompts = minDaysBetweenPrompts
        self.oncePerVersion = oncePerVersion
    }
}

/// What the rate prompt remembers between launches. The app keeps it in a preference.
///
///     state.recordLaunch()
///     if state.isDue(policy, version: config.appVersion) { ... requestReview() ... }
///     state.recordPrompt(version: config.appVersion)
public struct RatePromptState: Codable, Sendable, Equatable {
    public var firstLaunch: Date?
    public var launches: Int
    public var significantEvents: Int
    public var lastPrompt: Date?
    public var lastPromptVersion: String?

    public init(
        firstLaunch: Date? = nil,
        launches: Int = 0,
        significantEvents: Int = 0,
        lastPrompt: Date? = nil,
        lastPromptVersion: String? = nil
    ) {
        self.firstLaunch = firstLaunch
        self.launches = launches
        self.significantEvents = significantEvents
        self.lastPrompt = lastPrompt
        self.lastPromptVersion = lastPromptVersion
    }

    public mutating func recordLaunch(now: Date = Date()) {
        if firstLaunch == nil { firstLaunch = now }
        launches += 1
    }

    public mutating func recordSignificantEvent() {
        significantEvents += 1
    }

    public mutating func recordPrompt(version: String, now: Date = Date()) {
        lastPrompt = now
        lastPromptVersion = version
    }

    public func isDue(_ policy: RatePromptPolicy, version: String, now: Date = Date()) -> Bool {
        guard let firstLaunch,
              launches >= policy.minLaunches,
              significantEvents >= policy.minSignificantEvents,
              Self.days(from: firstLaunch, to: now) >= policy.minDaysSinceInstall
        else { return false }
        if policy.oncePerVersion, lastPromptVersion == version { return false }
        if let lastPrompt, Self.days(from: lastPrompt, to: now) < policy.minDaysBetweenPrompts { return false }
        return true
    }

    private static func days(from start: Date, to end: Date) -> Int {
        Int(end.timeIntervalSince(start) / 86_400)
    }
}

/// App Store links for a "Rate the app" row in Settings, which opens the review page directly.
public enum AppStoreLink {
    public static func app(id: String) -> URL? {
        URL(string: "https://apps.apple.com/app/id\(id)")
    }

    public static func writeReview(id: String) -> URL? {
        URL(string: "https://apps.apple.com/app/id\(id)?action=write-review")
    }
}

public extension View {
    /// Shows the system rating prompt when `isDue` is true, on appear or when it turns true,
    /// at most once while the view is on screen.
    /// `onRequested` runs right after, so the app can call `recordPrompt`.
    func tkRequestReview(when isDue: Bool, onRequested: @escaping @MainActor () -> Void) -> some View {
        modifier(RequestReviewModifier(isDue: isDue, onRequested: onRequested))
    }
}

private struct RequestReviewModifier: ViewModifier {
    let isDue: Bool
    let onRequested: @MainActor () -> Void
    @Environment(\.requestReview) private var requestReview
    /// `isDue` can be stale when the screen appears again before it re-renders.
    @State private var didAsk = false

    func body(content: Content) -> some View {
        content
            .onAppear(perform: askIfDue)
            .onChange(of: isDue) { _ in askIfDue() }
    }

    private func askIfDue() {
        guard isDue, !didAsk else { return }
        didAsk = true
        requestReview()
        onRequested()
    }
}
