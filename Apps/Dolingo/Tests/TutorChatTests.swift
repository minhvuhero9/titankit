import XCTest
import TitanAI
import TitanCore
import TitanStorage
@testable import Dolingo

@MainActor
final class TutorChatTests: XCTestCase {
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "TutorChatTests")!
        defaults.removePersistentDomain(forName: "TutorChatTests")
        return Preferences(defaults: defaults)
    }

    func testSendsAndStreamsTheReply() async {
        let preferences = makePreferences()
        let chat = TutorChat(service: MockChatService(wordDelay: .zero) { "Hi \($0)!" }, preferences: preferences)
        XCTAssertFalse(chat.canSend)
        chat.draft = "  An  "
        chat.send()
        XCTAssertEqual(chat.draft, "")
        XCTAssertTrue(chat.isReplying)
        XCTAssertTrue(chat.isWaitingForFirstWord)
        await chat.waitForReply()
        XCTAssertFalse(chat.isReplying)
        XCTAssertEqual(chat.messages.map(\.role), [.user, .assistant])
        XCTAssertEqual(chat.messages.map(\.text), ["An", "Hi An!"])

        let reopened = TutorChat(service: MockChatService(), preferences: preferences)
        XCTAssertEqual(reopened.messages.map(\.text), ["An", "Hi An!"])
    }

    func testAFailedReplyPutsTheQuestionBack() async {
        let chat = TutorChat(service: MockChatService(wordDelay: .zero, failure: .failed(.network(.offline))),
                             preferences: makePreferences())
        chat.draft = "How do I say cảm ơn?"
        chat.send()
        await chat.waitForReply()
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.draft, "How do I say cảm ơn?")
        XCTAssertEqual(chat.errorKey, "tutor.error.offline")
    }

    func testARefusalIsExplained() async {
        let chat = TutorChat(service: MockChatService(wordDelay: .zero, failure: .refused), preferences: makePreferences())
        chat.draft = "Hi"
        chat.send()
        await chat.waitForReply()
        XCTAssertEqual(chat.errorKey, "tutor.error.refused")
        chat.dismissError()
        XCTAssertNil(chat.errorKey)
    }

    func testRestartDropsTheTextSoFar() async {
        let chat = TutorChat(service: ScriptedChat(events: [.text("Wrong"), .restart, .text("Right"), .done]),
                             preferences: makePreferences())
        chat.draft = "Hi"
        chat.send()
        await chat.waitForReply()
        XCTAssertEqual(chat.messages.last?.text, "Right")
    }

    func testNewChatClearsEverything() async {
        let preferences = makePreferences()
        let chat = TutorChat(service: MockChatService(wordDelay: .zero), preferences: preferences)
        chat.draft = "Hi"
        chat.send()
        await chat.waitForReply()
        chat.clear()
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertTrue(TutorChat(service: MockChatService(), preferences: preferences).messages.isEmpty)
    }

    func testAnUnansweredQuestionComesBackOnReopen() {
        let preferences = makePreferences()
        preferences.set([ChatMessage(role: .user, text: "Hi"), ChatMessage(role: .assistant, text: "Hello!"),
                         ChatMessage(role: .user, text: "Still there?")], for: DolingoKeys.tutorChat)
        let chat = TutorChat(service: MockChatService(), preferences: preferences)
        XCTAssertEqual(chat.messages.map(\.text), ["Hi", "Hello!"])
        XCTAssertEqual(chat.draft, "Still there?")
    }

    func testAnEmptyReplyCountsAsFailed() async {
        let chat = TutorChat(service: ScriptedChat(events: [.done]), preferences: makePreferences())
        chat.draft = "Hi"
        chat.send()
        await chat.waitForReply()
        XCTAssertTrue(chat.messages.isEmpty)
        XCTAssertEqual(chat.errorKey, "tutor.error.failed")
    }

    func testSendsTheLearner() async {
        let service = ScriptedChat(events: [.text("Hello"), .done])
        let chat = TutorChat(service: service, preferences: makePreferences()) {
            ChatLearner(name: "An", level: "beginner")
        }
        chat.draft = "Hi"
        chat.send()
        await chat.waitForReply()
        XCTAssertEqual(service.learners.value, [ChatLearner(name: "An", level: "beginner")])
    }
}

/// Replays fixed events and remembers who asked.
private final class ScriptedChat: ChatService, @unchecked Sendable {
    let events: [ChatReplyEvent]
    let learners = Locked<[ChatLearner]>([])

    init(events: [ChatReplyEvent]) {
        self.events = events
    }

    func reply(to conversation: [ChatMessage], learner: ChatLearner) -> AsyncStream<ChatReplyEvent> {
        learners.mutate { $0.append(learner) }
        let events = events
        return AsyncStream { continuation in
            for event in events { continuation.yield(event) }
            continuation.finish()
        }
    }
}

private final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) {
        stored = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func mutate(_ change: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        change(&stored)
    }
}
