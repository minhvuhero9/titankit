import Foundation
import TitanCore

/// A ChatService that answers locally, a few words at a time like the real stream, for
/// previews, tests and running the app before the AI server exists.
public struct MockChatService: ChatService {
    /// The whole reply to the learner's last message.
    public var answer: @Sendable (String) -> String
    /// Sent instead of a reply when set.
    public var failure: ChatReplyEvent?
    public var wordDelay: Duration

    public init(
        wordDelay: Duration = .milliseconds(40),
        failure: ChatReplyEvent? = nil,
        answer: @escaping @Sendable (String) -> String = { "You said: \"\($0)\". Let's keep practising!" }
    ) {
        self.wordDelay = wordDelay
        self.failure = failure
        self.answer = answer
    }

    public func reply(to conversation: [ChatMessage], learner: ChatLearner) -> AsyncStream<ChatReplyEvent> {
        let last = conversation.last { $0.role == .user }?.text ?? ""
        let words = Self.pieces(of: answer(last))
        let failure = failure
        let delay = wordDelay
        return AsyncStream { continuation in
            let task = Task {
                if let failure {
                    continuation.yield(failure)
                    continuation.finish()
                    return
                }
                for word in words {
                    if delay > .zero { try? await Task.sleep(for: delay) }
                    if Task.isCancelled { break }
                    continuation.yield(.text(word))
                }
                continuation.yield(.done)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Words with the space before them kept, so joining them gives the text back.
    static func pieces(of text: String) -> [String] {
        var pieces: [String] = []
        var current = ""
        for character in text {
            if character == " ", !current.isEmpty, current != " " {
                pieces.append(current)
                current = ""
            }
            current.append(character)
        }
        if !current.isEmpty { pieces.append(current) }
        return pieces
    }
}
