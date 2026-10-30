import Foundation
import TitanCore

/// One message of a chat, from the learner or from the tutor.
public struct ChatMessage: Codable, Sendable, Equatable, Identifiable {
    public enum Role: String, Codable, Sendable {
        case user, assistant
    }

    public let id: UUID
    public let role: Role
    public var text: String

    public init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

/// What the tutor may know about the learner to pitch its replies. Both optional.
public struct ChatLearner: Codable, Sendable, Equatable {
    public var name: String?
    /// "beginner", "elementary", "intermediate" or "advanced".
    public var level: String?

    public init(name: String? = nil, level: String? = nil) {
        self.name = name
        self.level = level
    }
}

/// What arrives while a reply streams in.
public enum ChatReplyEvent: Sendable, Equatable {
    /// The next piece of the reply, to append.
    case text(String)
    /// Another model took over: drop what arrived so far for this reply.
    case restart
    case done
    /// The tutor would not answer this.
    case refused
    case failed(TitanError)
}

/// Sends the conversation so far and streams the tutor's next reply.
/// The stream always ends with `.done`, `.refused` or `.failed`, and stops the request when
/// the caller stops reading.
public protocol ChatService: Sendable {
    func reply(to conversation: [ChatMessage], learner: ChatLearner) -> AsyncStream<ChatReplyEvent>
}

/// The signed-in user's ID token for the AI server, or nil when there is none; `true` asks for
/// a fresh one after the server refused the last.
public typealias AITokenProvider = @Sendable (_ forceRefresh: Bool) async -> String?
