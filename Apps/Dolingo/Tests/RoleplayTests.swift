import XCTest
import TitanCore
import TitanSpeech
@testable import Dolingo

@MainActor
final class RoleplayTests: XCTestCase {
    private func meetingFriends() async throws -> Roleplay {
        let all = try await BundledRoleplayRepository().roleplays(language: "en")
        return try XCTUnwrap(all.first { $0.id == "en.friends" })
    }

    func testBundledRoleplaysAreWellFormed() async throws {
        let repository = BundledRoleplayRepository()
        for language in [AppConfig.learningLanguage] {
            let roleplays = try await repository.roleplays(language: language)
            XCTAssertEqual(roleplays.count, 6, language)
            XCTAssertEqual(roleplays.filter { !$0.isPremium }.count, 3, language)
            for roleplay in roleplays {
                let taskIds = Set(roleplay.tasks.map(\.id))
                XCTAssertEqual(roleplay.tasks.count, 4, roleplay.id)
                XCTAssertTrue(roleplay.turns.last?.replies.isEmpty ?? false, "\(roleplay.id) ends with a goodbye")
                XCTAssertTrue(roleplay.turns.dropLast().allSatisfy { !$0.replies.isEmpty }, roleplay.id)
                let completable = Set(roleplay.turns.flatMap { $0.replies.flatMap(\.completes) })
                XCTAssertTrue(completable.isSubset(of: taskIds), "\(roleplay.id) completes unknown tasks")
                XCTAssertEqual(completable, taskIds, "\(roleplay.id): every task can be done")
            }
        }
        let none = try await repository.roleplays(language: "es")
        XCTAssertTrue(none.isEmpty)
    }

    func testSpeakingTheRepliesFinishesEveryTask() async throws {
        let roleplay = try await meetingFriends()
        let speech = MockSpeechRecognizer(transcripts: [
            "hi my name is alex",
            "I'm from Vietnam where are you from",
            "I like reading and music what about you",
        ])
        let viewModel = RoleplayViewModel(roleplay: roleplay, language: "en", speech: speech)
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.state, .ready)

        await viewModel.speak()
        XCTAssertEqual(viewModel.messages.count, 3)
        XCTAssertTrue(viewModel.messages[1].isMine)
        XCTAssertEqual(viewModel.completedTaskCount, 1)

        await viewModel.speak()
        await viewModel.speak()
        XCTAssertEqual(viewModel.state, .finished)
        XCTAssertEqual(viewModel.completedTaskCount, 4)
        XCTAssertEqual(viewModel.messages.last?.isMine, false)
        XCTAssertEqual(speech.requestedLanguages, ["en", "en", "en"])
    }

    func testUnrelatedAnswerIsMissedAndKeepsTheTurn() async throws {
        let roleplay = try await meetingFriends()
        let viewModel = RoleplayViewModel(roleplay: roleplay, language: "en", speech: MockSpeechRecognizer(transcripts: ["the weather is nice"]))
        await viewModel.speak()
        guard case let .missed(score) = viewModel.state else { return XCTFail("Expected a miss") }
        XCTAssertFalse(score.verdict.isPass)
        XCTAssertEqual(viewModel.messages.count, 1)
    }

    func testWithoutMicrophoneTheHintCanBeSent() async throws {
        let roleplay = try await meetingFriends()
        let viewModel = RoleplayViewModel(roleplay: roleplay, language: "en", speech: MockSpeechRecognizer(isAuthorized: false))
        await viewModel.speak()
        XCTAssertTrue(viewModel.isMicBlocked)
        let hint = try XCTUnwrap(viewModel.hint)
        viewModel.send(hint)
        XCTAssertEqual(viewModel.messages.count, 3)
        XCTAssertEqual(viewModel.completedTaskCount, 1)
    }
}
