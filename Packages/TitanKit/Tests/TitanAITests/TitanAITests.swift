import XCTest
import TitanCore
@testable import TitanAI

final class RemoteChatServiceTests: XCTestCase {
    private let service = RemoteChatService(baseURL: URL(string: "https://ai.example.com")!, clientKey: "key")

    func testRequestCarriesTheConversationAndKey() throws {
        let request = try service.makeRequest(
            conversation: [ChatMessage(role: .user, text: "Hi"), ChatMessage(role: .assistant, text: "Hello!"),
                           ChatMessage(role: .user, text: "How are you?")],
            learner: ChatLearner(level: "beginner")
        )
        XCTAssertEqual(request.url?.absoluteString, "https://ai.example.com/v1/chat")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Dolingo-Key"), "key")
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let turns = try XCTUnwrap(json["turns"] as? [[String: String]])
        XCTAssertEqual(turns.map { $0["role"] }, ["user", "assistant", "user"])
        XCTAssertEqual(turns.last?["text"], "How are you?")
        XCTAssertEqual((json["learner"] as? [String: String])?["level"], "beginner")
    }

    func testReadsTheServerEvents() {
        XCTAssertEqual(RemoteChatService.event(fromLine: #"data: {"type":"text","text":"Hello"}"#), .text("Hello"))
        XCTAssertEqual(RemoteChatService.event(fromLine: #"data: {"type":"restart"}"#), .restart)
        XCTAssertEqual(RemoteChatService.event(fromLine: #"data: {"type":"done"}"#), .done)
        XCTAssertEqual(RemoteChatService.event(fromLine: #"data: {"type":"error","code":"refused"}"#), .refused)
        XCTAssertEqual(RemoteChatService.event(fromLine: #"data: {"type":"error","code":"busy"}"#),
                       .failed(.network(.server(statusCode: 503))))
        XCTAssertNil(RemoteChatService.event(fromLine: ""))
        XCTAssertNil(RemoteChatService.event(fromLine: ": keep-alive"))
        XCTAssertNil(RemoteChatService.event(fromLine: #"data: {"type":"ping"}"#))
    }

    func testSignedRequestsCarryTheToken() throws {
        let request = try service.makeRequest(conversation: [ChatMessage(role: .user, text: "Hi")], learner: ChatLearner())
        XCTAssertNil(RemoteChatService.signed(request, token: nil).value(forHTTPHeaderField: "Authorization"))
        XCTAssertNil(RemoteChatService.signed(request, token: "").value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(RemoteChatService.signed(request, token: "abc").value(forHTTPHeaderField: "Authorization"), "Bearer abc")
        let keyless = RemoteChatService(baseURL: URL(string: "https://ai.example.com")!, clientKey: "")
        let plain = try keyless.makeRequest(conversation: [ChatMessage(role: .user, text: "Hi")], learner: ChatLearner())
        XCTAssertNil(plain.value(forHTTPHeaderField: "X-Dolingo-Key"))
    }

    func testStatusCodes() {
        XCTAssertNil(RemoteChatService.failure(for: 200))
        XCTAssertEqual(RemoteChatService.failure(for: 401), .unauthorized)
        XCTAssertEqual(RemoteChatService.failure(for: 500), .network(.server(statusCode: 500)))
        XCTAssertEqual(RemoteChatService.map(URLError(.notConnectedToInternet)), .network(.offline))
    }
}

final class AIServerClientTests: XCTestCase {
    private struct Form: Codable, Sendable {
        let title: String
    }

    func testPostsJSONWithTheKey() throws {
        let client = AIServerClient(baseURL: URL(string: "https://ai.example.com")!, clientKey: "key")
        let request = try client.makeRequest("v1/roleplay/draft", body: Form(title: "Pizza"))
        XCTAssertEqual(request.url?.absoluteString, "https://ai.example.com/v1/roleplay/draft")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Dolingo-Key"), "key")
        let body = try JSONDecoder().decode(Form.self, from: try XCTUnwrap(request.httpBody))
        XCTAssertEqual(body.title, "Pizza")
    }
}

final class MockChatServiceTests: XCTestCase {
    func testStreamsTheAnswerWordByWord() async {
        let service = MockChatService(wordDelay: .zero) { "Hi \($0)!" }
        var pieces: [String] = []
        var last: ChatReplyEvent?
        for await event in service.reply(to: [ChatMessage(role: .user, text: "An")], learner: ChatLearner()) {
            if case let .text(piece) = event { pieces.append(piece) } else { last = event }
        }
        XCTAssertEqual(pieces, ["Hi", " An!"])
        XCTAssertEqual(last, .done)
    }

    func testCanFail() async {
        let service = MockChatService(wordDelay: .zero, failure: .failed(.network(.offline)))
        var events: [ChatReplyEvent] = []
        for await event in service.reply(to: [ChatMessage(role: .user, text: "Hi")], learner: ChatLearner()) {
            events.append(event)
        }
        XCTAssertEqual(events, [.failed(.network(.offline))])
    }

    func testPiecesJoinBackToTheText() {
        let text = "Hello  there, how are you?"
        XCTAssertEqual(MockChatService.pieces(of: text).joined(), text)
    }
}
