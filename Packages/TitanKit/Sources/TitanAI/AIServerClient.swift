import Foundation
import TitanCore

/// What the AI server answered: the value, or that the model declined to answer.
public enum AIAnswer<Value: Sendable>: Sendable {
    case answer(Value)
    case refused
}

extension AIAnswer: Equatable where Value: Equatable {}

/// Plain JSON calls to the app's AI server, for answers that come back in one piece (a filled-in
/// form, the next roleplay turn). Streaming chat goes through `RemoteChatService`.
///
///     let client = AIServerClient(baseURL: url, clientKey: key)
///     let draft = try await client.post("v1/roleplay/draft", body: form, as: Draft.self)
public struct AIServerClient: Sendable {
    public let baseURL: URL
    private let clientKey: String
    private let session: URLSession

    public init(baseURL: URL, clientKey: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.clientKey = clientKey
        self.session = session
    }

    /// Throws `.unauthorized` for a wrong client key, `.network` when offline or the server is
    /// busy, `.decoding` when the answer isn't the expected JSON.
    public func post<Body: Encodable & Sendable, Value: Decodable & Sendable>(
        _ path: String,
        body: Body,
        as type: Value.Type
    ) async throws(TitanError) -> AIAnswer<Value> {
        let request: URLRequest
        do {
            request = try makeRequest(path, body: body)
        } catch {
            throw .unknown("could not encode the request")
        }
        let reply: (Data, URLResponse)
        do {
            reply = try await session.data(for: request)
        } catch {
            throw RemoteChatService.map(error)
        }
        let (data, response) = reply
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 422 { return .refused }
        if let failure = RemoteChatService.failure(for: status) { throw failure }
        do {
            return .answer(try JSONDecoder().decode(Value.self, from: data))
        } catch {
            throw .decoding(error.localizedDescription)
        }
    }

    func makeRequest<Body: Encodable>(_ path: String, body: Body) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(clientKey, forHTTPHeaderField: "X-Dolingo-Key")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}
