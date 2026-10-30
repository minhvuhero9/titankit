import Foundation
import TitanAI
import TitanCore
import TitanStorage

/// "Chat with Dolingo": the conversation with the AI tutor, saved in Preferences, and the
/// reply streaming in word by word.
@MainActor
final class TutorChat: ObservableObject {
    /// Older messages are dropped from storage past this; the server only reads the latest ones.
    static let maxStoredMessages = 100
    /// Longest message the learner can send; the server refuses longer ones.
    static let maxMessageLength = 1000

    @Published private(set) var messages: [ChatMessage]
    /// From sending until the reply is complete.
    @Published private(set) var isReplying = false
    /// Localizable key of the last error, shown as a toast.
    @Published private(set) var errorKey: String?
    @Published var draft = ""

    private let service: any ChatService
    private let preferences: Preferences
    private let learner: @MainActor () async -> ChatLearner
    private var replyTask: Task<Void, Never>?

    init(service: any ChatService, preferences: Preferences,
         learner: @escaping @MainActor () async -> ChatLearner = { ChatLearner() }) {
        self.service = service
        self.preferences = preferences
        self.learner = learner
        var saved = preferences.value(DolingoKeys.tutorChat)
        // The app closed before the last question got its reply: offer it again.
        let unanswered = saved.last?.role == .user ? saved.popLast() : nil
        messages = saved
        if let unanswered { draft = unanswered.text }
    }

    var canSend: Bool {
        !draft.isBlank && !isReplying
    }

    /// The reply has started arriving, so the typing dots can go.
    var isWaitingForFirstWord: Bool {
        isReplying && messages.last?.role == .user
    }

    func send() {
        guard canSend else { return }
        let text = String(draft.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxMessageLength))
        draft = ""
        errorKey = nil
        messages.append(ChatMessage(role: .user, text: text))
        save()
        isReplying = true
        replyTask = Task { [weak self] in await self?.streamReply() }
    }

    /// Waits for the reply started by `send()`.
    func waitForReply() async {
        await replyTask?.value
    }

    /// The ⋮ menu's "New chat".
    func clear() {
        replyTask?.cancel()
        replyTask = nil
        isReplying = false
        errorKey = nil
        messages = []
        save()
    }

    func dismissError() {
        errorKey = nil
    }

    private func streamReply() async {
        defer { isReplying = false }
        let learner = await learner()
        var replyIndex: Int?
        for await event in service.reply(to: messages, learner: learner) {
            if Task.isCancelled { return }
            switch event {
            case let .text(piece):
                if let index = replyIndex {
                    messages[index].text += piece
                } else {
                    messages.append(ChatMessage(role: .assistant, text: piece))
                    replyIndex = messages.count - 1
                }
            case .restart:
                if let index = replyIndex { messages[index].text = "" }
            case .done:
                if replyIndex.map({ messages[$0].text.isBlank }) ?? true {
                    takeBackQuestion(replyIndex: replyIndex, errorKey: "tutor.error.failed")
                    return
                }
            case .refused:
                takeBackQuestion(replyIndex: replyIndex, errorKey: "tutor.error.refused")
                return
            case let .failed(error):
                if error == .cancelled { return }
                takeBackQuestion(replyIndex: replyIndex,
                                 errorKey: error == .network(.offline) ? "tutor.error.offline" : "tutor.error.failed")
                return
            }
        }
        save()
    }

    /// No reply came: the question goes back into the field so it can be sent again, and the
    /// conversation keeps alternating learner, tutor.
    private func takeBackQuestion(replyIndex: Int?, errorKey: String) {
        if let replyIndex { messages.remove(at: replyIndex) }
        if messages.last?.role == .user, let question = messages.popLast() {
            draft = question.text
        }
        self.errorKey = errorKey
        save()
    }

    private func save() {
        preferences.set(Array(messages.suffix(Self.maxStoredMessages)), for: DolingoKeys.tutorChat)
    }
}
