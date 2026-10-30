import XCTest
import TitanAI
import TitanCore
import TitanSpeech
import TitanStorage
@testable import Dolingo

@MainActor
final class MyRoleplaysTests: XCTestCase {
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "MyRoleplaysTests")!
        defaults.removePersistentDomain(forName: "MyRoleplaysTests")
        return Preferences(defaults: defaults)
    }

    private func roleplay(_ title: String) -> CustomRoleplay {
        CustomRoleplay(emoji: "🍕", title: title, myRole: "Customer", aiRole: "Waiter", scenario: "You order.", tasks: [])
    }

    func testNewRoleplaysGoOnTopAndUseATrial() {
        let preferences = makePreferences()
        let mine = MyRoleplays(preferences: preferences)
        XCTAssertEqual(mine.trialsLeft, MyRoleplays.freeCreations)
        mine.save(roleplay("Pizza"))
        mine.save(roleplay("Gym"))
        XCTAssertEqual(mine.roleplays.map(\.title), ["Gym", "Pizza"])
        XCTAssertEqual(mine.trialsLeft, MyRoleplays.freeCreations - 2)

        let reopened = MyRoleplays(preferences: preferences)
        XCTAssertEqual(reopened.roleplays.map(\.title), ["Gym", "Pizza"])
        XCTAssertEqual(reopened.creationsUsed, 2)
    }

    func testEditReplacesAndDeleteKeepsTheTrialUsed() {
        let mine = MyRoleplays(preferences: makePreferences())
        var pizza = roleplay("Pizza")
        mine.save(pizza)
        pizza.title = "Ordering Pizza"
        mine.save(pizza)
        XCTAssertEqual(mine.roleplays.map(\.title), ["Ordering Pizza"])
        XCTAssertEqual(mine.creationsUsed, 1)
        mine.delete(id: pizza.id)
        XCTAssertTrue(mine.roleplays.isEmpty)
        XCTAssertEqual(mine.creationsUsed, 1)
    }
}

@MainActor
final class CreateRoleplayViewModelTests: XCTestCase {
    func testStartFillsTheEmptyFieldsAndKeepsTheLearnersOnes() async {
        let viewModel = CreateRoleplayViewModel(ai: MockRoleplayAI())
        viewModel.myRole = "  Tourist "
        let roleplay = await viewModel.create()
        XCTAssertEqual(roleplay?.myRole, "Tourist")
        XCTAssertEqual(roleplay?.aiRole, "Pizza Shop Employee")
        XCTAssertEqual(roleplay?.emoji, "🍕")
        XCTAssertEqual(roleplay?.tasks.map(\.id), ["goal1", "goal2", "goal3"])
        XCTAssertEqual(roleplay?.tasks.first?.meaning["vi"], "Chào người phục vụ")
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testGoalsCanBeTurnedOff() async {
        let viewModel = CreateRoleplayViewModel(ai: MockRoleplayAI())
        viewModel.withGoals = false
        let roleplay = await viewModel.create()
        XCTAssertEqual(roleplay?.tasks, [])
    }

    func testSparkleFillsOneField() async {
        let viewModel = CreateRoleplayViewModel(ai: MockRoleplayAI())
        await viewModel.fill(.scenario)
        XCTAssertEqual(viewModel.scenario, "You're at a pizza shop and want to order a pizza.")
        XCTAssertEqual(viewModel.myRole, "")
        XCTAssertEqual(viewModel.title, "Ordering Pizza")
        XCTAssertEqual(viewModel.emoji, "🍕")
        XCTAssertNil(viewModel.fillingField)
    }

    func testEditingKeepsTheIdAndEmoji() async {
        let existing = CustomRoleplay(emoji: "🏋️", title: "At the Gym", myRole: "Member", aiRole: "Trainer",
                                      scenario: "You ask for help.", tasks: [])
        let viewModel = CreateRoleplayViewModel(editing: existing, ai: MockRoleplayAI())
        XCTAssertFalse(viewModel.withGoals)
        let edited = await viewModel.create()
        XCTAssertEqual(edited?.id, existing.id)
        XCTAssertEqual(edited?.emoji, "🏋️")
        XCTAssertEqual(edited?.title, "At the Gym")
    }

    func testARefusalIsExplained() async {
        let viewModel = CreateRoleplayViewModel(ai: RefusingRoleplayAI())
        let roleplay = await viewModel.create()
        XCTAssertNil(roleplay)
        XCTAssertEqual(viewModel.errorKey, "createRoleplay.error.refused")
    }
}

@MainActor
final class AIRoleplayViewModelTests: XCTestCase {
    private let roleplay = CustomRoleplay(
        emoji: "🍕", title: "Ordering Pizza", myRole: "Customer", aiRole: "Waiter", scenario: "You order.",
        tasks: [RoleplayTask(id: "goal1", text: "Greet", meaning: ["vi": "Chào"]),
                RoleplayTask(id: "goal2", text: "Order", meaning: ["vi": "Gọi món"])]
    )

    func testTheAIOpensAndTheLearnerSpeaksUntilTheEnd() async {
        let speech = MockSpeechRecognizer(transcripts: ["Hello!", "A pizza, please."])
        let viewModel = AIRoleplayViewModel(roleplay: roleplay, language: "en", ai: MockRoleplayAI(), speech: speech)
        await viewModel.start()
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.messages.map(\.isMine), [false])
        XCTAssertEqual(viewModel.messages.first?.phrase.meaning["vi"], "Chào bạn! Bạn muốn dùng gì?")
        XCTAssertNotNil(viewModel.hint)

        await viewModel.speak()
        XCTAssertEqual(viewModel.messages.map(\.isMine), [false, true, false])
        XCTAssertEqual(viewModel.messages[1].phrase.text, "Hello!")
        XCTAssertEqual(viewModel.completedTaskCount, 1)

        await viewModel.speak()
        XCTAssertEqual(viewModel.completedTaskCount, 2)
        XCTAssertEqual(viewModel.state, .finished)
        XCTAssertNil(viewModel.hint)
    }

    func testSilenceAsksAgain() async {
        let viewModel = AIRoleplayViewModel(roleplay: roleplay, language: "en", ai: MockRoleplayAI(),
                                            speech: MockSpeechRecognizer(transcripts: [""]))
        await viewModel.start()
        await viewModel.speak()
        XCTAssertEqual(viewModel.state, .notHeard)
        XCTAssertEqual(viewModel.messages.count, 1)
    }

    func testAFailedOpeningCanBeRetried() async {
        let viewModel = AIRoleplayViewModel(roleplay: roleplay, language: "en", ai: RefusingRoleplayAI(),
                                            speech: MockSpeechRecognizer())
        await viewModel.start()
        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertEqual(viewModel.errorKey, "createRoleplay.error.refused")
    }

    func testTheHintCanBeSentWithoutTheMicrophone() async {
        let viewModel = AIRoleplayViewModel(roleplay: roleplay, language: "en", ai: MockRoleplayAI(),
                                            speech: MockSpeechRecognizer(isAuthorized: false))
        await viewModel.start()
        await viewModel.speak()
        XCTAssertTrue(viewModel.isMicBlocked)
        await viewModel.say(viewModel.hint?.text ?? "")
        XCTAssertEqual(viewModel.messages.count, 3)
    }
}

private struct RefusingRoleplayAI: RoleplayAI {
    func draft(_ form: RoleplayForm) async throws(TitanError) -> AIAnswer<RoleplayDraft> { .refused }
    func turn(_ request: RoleplayTurnRequest) async throws(TitanError) -> AIAnswer<AIRoleplayTurn> { .refused }
}
