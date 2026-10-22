import XCTest
@testable import TitanFeatures

final class RatePromptTests: XCTestCase {
    private let day: TimeInterval = 86_400
    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let policy = RatePromptPolicy(minLaunches: 2, minSignificantEvents: 1, minDaysSinceInstall: 3, minDaysBetweenPrompts: 30)

    /// Two launches and one event, the first launch at `start`.
    private func readyState() -> RatePromptState {
        var state = RatePromptState()
        state.recordLaunch(now: start)
        state.recordLaunch(now: start.addingTimeInterval(day))
        state.recordSignificantEvent()
        return state
    }

    func testNotDueBeforeAnyLaunch() {
        XCTAssertFalse(RatePromptState().isDue(RatePromptPolicy(minLaunches: 0, minSignificantEvents: 0, minDaysSinceInstall: 0), version: "1.0"))
    }

    func testKeepsTheFirstLaunchDate() {
        let state = readyState()
        XCTAssertEqual(state.firstLaunch, start)
        XCTAssertEqual(state.launches, 2)
        XCTAssertEqual(state.significantEvents, 1)
    }

    func testWaitsForEnoughDaysLaunchesAndEvents() {
        let state = readyState()
        XCTAssertFalse(state.isDue(policy, version: "1.0", now: start.addingTimeInterval(2 * day)))
        XCTAssertTrue(state.isDue(policy, version: "1.0", now: start.addingTimeInterval(3 * day)))

        var fewLaunches = RatePromptState()
        fewLaunches.recordLaunch(now: start)
        fewLaunches.recordSignificantEvent()
        XCTAssertFalse(fewLaunches.isDue(policy, version: "1.0", now: start.addingTimeInterval(10 * day)))

        var noEvents = RatePromptState()
        noEvents.recordLaunch(now: start)
        noEvents.recordLaunch(now: start)
        XCTAssertFalse(noEvents.isDue(policy, version: "1.0", now: start.addingTimeInterval(10 * day)))
    }

    func testAsksOncePerVersionAndWaitsBetweenPrompts() {
        var state = readyState()
        let firstPrompt = start.addingTimeInterval(3 * day)
        state.recordPrompt(version: "1.0", now: firstPrompt)
        XCTAssertFalse(state.isDue(policy, version: "1.0", now: firstPrompt.addingTimeInterval(100 * day)))
        XCTAssertFalse(state.isDue(policy, version: "1.1", now: firstPrompt.addingTimeInterval(29 * day)))
        XCTAssertTrue(state.isDue(policy, version: "1.1", now: firstPrompt.addingTimeInterval(30 * day)))

        var everyVersion = policy
        everyVersion.oncePerVersion = false
        XCTAssertTrue(state.isDue(everyVersion, version: "1.0", now: firstPrompt.addingTimeInterval(30 * day)))
    }

    func testSurvivesARoundTripThroughJSON() throws {
        var state = readyState()
        state.recordPrompt(version: "1.0", now: start)
        let decoded = try JSONDecoder().decode(RatePromptState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(decoded, state)
    }

    func testAppStoreLinks() {
        XCTAssertEqual(AppStoreLink.app(id: "123")?.absoluteString, "https://apps.apple.com/app/id123")
        XCTAssertEqual(AppStoreLink.writeReview(id: "123")?.absoluteString, "https://apps.apple.com/app/id123?action=write-review")
    }
}
