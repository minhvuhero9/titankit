import XCTest
import TitanAI
import TitanAnalytics
import TitanAuth
import TitanPurchase
import TitanStorage
@testable import Dolingo

@MainActor
final class AnalyticsEventsTests: XCTestCase {
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "AnalyticsEventsTests")!
        defaults.removePersistentDomain(forName: "AnalyticsEventsTests")
        return Preferences(defaults: defaults)
    }

    func testEveryDolingoEventHasAValidName() {
        for event in AnalyticsEvent.dolingoSamples {
            XCTAssertTrue(AnalyticsEvent.isValidName(event.name), event.name)
            for key in event.parameters.keys {
                XCTAssertTrue(AnalyticsEvent.isValidName(key), "\(event.name).\(key)")
            }
        }
    }

    func testLessonsRoleplaysAndBadgesAreTracked() {
        let spy = SpyAnalyticsService()
        let store = ActivityStore(preferences: makePreferences(), analytics: spy)
        store.recordLesson(accuracy: 0.876, seconds: 150)
        store.recordLesson(accuracy: nil, seconds: 30)
        store.recordRoleplay(tasksDone: 2, tasksTotal: 3, seconds: 90)

        let names = spy.events.map(\.name)
        XCTAssertEqual(names.filter { $0 == "lesson_completed" }.count, 2)
        XCTAssertTrue(names.contains("roleplay_completed"))
        XCTAssertTrue(names.contains("badge_earned"), "the first lesson earns Rising Star")
        let firstLesson = spy.events.first { $0.name == "lesson_completed" }
        XCTAssertEqual(firstLesson?.parameters["accuracy"], .int(88))
        XCTAssertEqual(firstLesson?.parameters["minutes"], .int(3))
        let secondLesson = spy.events.last { $0.name == "lesson_completed" }
        XCTAssertNil(secondLesson?.parameters["accuracy"], "no microphone, no accuracy")
    }

    func testATutorQuestionIsCountedWithoutItsText() async {
        let spy = SpyAnalyticsService()
        let chat = TutorChat(service: MockChatService(wordDelay: .zero), preferences: makePreferences(), analytics: spy)
        chat.draft = "How do I order a coffee?"
        chat.send()
        await chat.waitForReply()
        XCTAssertEqual(spy.events, [.tutorMessageSent])
    }

    func testDeletingTheAccountIsTrackedAndForgetsTheUser() async {
        let analytics = SpyAnalyticsService()
        let crash = SpyAnalyticsService()
        let user = AuthUser(id: "u1", email: "a@b.c", provider: .email)
        let flow = AppFlow(auth: MockAuthService(), preferences: makePreferences(), analytics: analytics, crash: crash)
        flow.didSignIn(user, isNew: false)
        XCTAssertEqual(analytics.userId, "u1")
        XCTAssertEqual(crash.userId, "u1")

        flow.didDeleteAccount()
        XCTAssertEqual(analytics.events.last, .accountDeleted)
        XCTAssertNil(analytics.userId)
        XCTAssertNil(crash.userId)
    }

    func testIsPremiumFollowsWhatTheUserOwns() async {
        let spy = SpyAnalyticsService()
        let purchase = MockPurchaseService()
        let container = AppContainer.preview(analytics: spy, purchase: purchase)
        let task = Task { await container.trackPremium() }
        defer { task.cancel() }

        await waitUntil { spy.properties["is_premium"] == "false" }
        purchase.setEntitlements(Entitlements(isPremium: true, activeProductIds: ["premium.yearly"]))
        await waitUntil { spy.properties["is_premium"] == "true" }
        XCTAssertEqual(spy.properties["is_premium"], "true")
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
