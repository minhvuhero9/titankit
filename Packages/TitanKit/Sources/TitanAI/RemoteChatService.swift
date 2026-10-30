import Foundation
import TitanCore

/// Talks to the app's AI server: `POST <baseURL>/v1/chat` with the conversation, and reads the
/// reply back as server-sent events, one JSON event per `data:` line.
///
///     let chat = RemoteChatService(baseURL: URL(string: "https://ai.example.com")!, clientKey: "...")
///     for await event in chat.reply(to: messages, learner: ChatLearner(level: "beginner")) { ... }
public struct RemoteChatService: ChatService {
    public let baseURL: URL
    private let clientKey: String
    private let session: URLSession

    public init(baseURL: URL, clientKey: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.clientKey = clientKey
        self.session = session
    }

    public func reply(to conversation: [ChatMessage], learner: ChatLearner) -> AsyncStream<ChatReplyEvent> {
        let request: URLRequest
        do {
            request = try makeRequest(conversation: conversation, learner: learner)
        } catch {
            return AsyncStream { continuation in
                continuation.yield(.failed(.unknown("could not encode the chat")))
                continuation.finish()
            }
        }
        let session = session
        return AsyncStream { continuation in
            let task = Task {
                let last = await Self.stream(request, session: session) { continuation.yield($0) }
                continuation.yield(last)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func makeRequest(conversation: [ChatMessage], learner: ChatLearner) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/chat"))
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue(clientKey, forHTTPHeaderField: "X-Dolingo-Key")
        let turns = conversation.map { WireTurn(role: $0.role.rawValue, text: $0.text) }
        request.httpBody = try JSONEncoder().encode(WireRequest(turns: turns, learner: learner))
        return request
    }

    /// Sends each event to `emit` and returns the last one: `.done`, `.refused` or `.failed`.
    private static func stream(
        _ request: URLRequest,
        session: URLSession,
        emit: (ChatReplyEvent) -> Void
    ) async -> ChatReplyEvent {
        do {
            let (bytes, response) = try await session.bytes(for: request)
            if let failure = failure(for: (response as? HTTPURLResponse)?.statusCode ?? 0) {
                return .failed(failure)
            }
            for try await line in bytes.lines {
                guard let event = event(fromLine: line) else { continue }
                switch event {
                case .text, .restart: emit(event)
                case .done, .refused, .failed: return event
                }
            }
            // The server always ends with done or error; anything else is a cut connection.
            return .failed(.network(.offline))
        } catch {
            return .failed(map(error))
        }
    }

    static func failure(for statusCode: Int) -> TitanError? {
        switch statusCode {
        case 200..<300: nil
        case 401: .unauthorized
        case 404: .notFound
        default: .network(.server(statusCode: statusCode))
        }
    }

    /// One line of the event stream; nil for blank lines, comments and unknown events.
    static func event(fromLine line: String) -> ChatReplyEvent? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
        guard let data = payload.data(using: .utf8),
              let wire = try? JSONDecoder().decode(WireEvent.self, from: data) else { return nil }
        switch wire.type {
        case "text": return wire.text.map(ChatReplyEvent.text)
        case "restart": return .restart
        case "done": return .done
        case "error":
            switch wire.code {
            case "refused": return .refused
            case "busy", "unavailable": return .failed(.network(.server(statusCode: 503)))
            default: return .failed(.unknown(wire.code ?? "error"))
            }
        default: return nil
        }
    }

    static func map(_ error: any Error) -> TitanError {
        if error is CancellationError { return .cancelled }
        guard let urlError = error as? URLError else { return .unknown(String(describing: error)) }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: return .network(.offline)
        case .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed: return .network(.timeout)
        case .cancelled: return .cancelled
        default: return .unknown(urlError.localizedDescription)
        }
    }
}

private struct WireTurn: Encodable {
    let role: String
    let text: String
}

private struct WireRequest: Encodable {
    let turns: [WireTurn]
    let learner: ChatLearner
}

private struct WireEvent: Decodable {
    let type: String
    let text: String?
    let code: String?
}
