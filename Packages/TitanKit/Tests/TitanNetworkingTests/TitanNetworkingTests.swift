import XCTest
import TitanCore
@testable import TitanNetworking

private struct User: Decodable, Equatable, Sendable {
    let id: Int
    let displayName: String
}

private struct GetProfile: Endpoint {
    typealias Response = User
    var path: String { "/v1/me" }
    var query: [String: String] { ["lang": "vi"] }
}

private struct Ping: Endpoint {
    typealias Response = EmptyResponse
    var path: String { "/health" }
    var method: HTTPMethod { .post }
    var requiresAuth: Bool { false }
}

// MARK: - DefaultAPIClient

final class DefaultAPIClientTests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testDecodesSnakeCaseResponseAndBuildsURL() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.test/v1/me?lang=vi")
            XCTAssertEqual(request.httpMethod, "GET")
            return (200, Data(#"{"id": 7, "display_name": "Jack"}"#.utf8))
        }
        let user = try await makeClient().send(GetProfile())
        XCTAssertEqual(user, User(id: 7, displayName: "Jack"))
    }

    func testEmptyResponseIgnoresBody() async throws {
        StubURLProtocol.handler = { _ in (204, Data()) }
        let response = try await makeClient().send(Ping())
        XCTAssertEqual(response, EmptyResponse())
    }

    func testStatusCodesMapToTitanError() async {
        let cases: [(Int, TitanError)] = [
            (401, .unauthorized),
            (404, .notFound),
            (500, .network(.server(statusCode: 500))),
        ]
        for (status, expected) in cases {
            StubURLProtocol.handler = { _ in (status, Data()) }
            await assertThrows(expected) { try await self.makeClient().send(GetProfile()) }
        }
    }

    func testBadJSONIsDecodingError() async {
        StubURLProtocol.handler = { _ in (200, Data("not json".utf8)) }
        do {
            _ = try await makeClient().send(GetProfile())
            XCTFail("Expected an error")
        } catch {
            guard case .decoding = error else { return XCTFail("Got \(error)") }
        }
    }

    func testURLErrorsAreMapped() {
        XCTAssertEqual(DefaultAPIClient.map(URLError(.notConnectedToInternet)), .network(.offline))
        XCTAssertEqual(DefaultAPIClient.map(URLError(.timedOut)), .network(.timeout))
        XCTAssertEqual(DefaultAPIClient.map(URLError(.cancelled)), .cancelled)
        XCTAssertEqual(DefaultAPIClient.map(CancellationError()), .cancelled)
    }

    func testAuthInterceptorSkippedForPublicEndpoints() async throws {
        let tokens = StubTokens(access: "abc")
        StubURLProtocol.handler = { request in
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (200, Data())
        }
        _ = try await makeClient(interceptors: [AuthInterceptor(tokens: tokens)]).send(Ping())
    }

    func testAuthInterceptorAddsBearerToken() async throws {
        let tokens = StubTokens(access: "abc")
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer abc")
            return (200, Data(#"{"id": 1, "display_name": "A"}"#.utf8))
        }
        _ = try await makeClient(interceptors: [AuthInterceptor(tokens: tokens)]).send(GetProfile())
    }

    private func makeClient(interceptors: [any Interceptor] = []) -> DefaultAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return DefaultAPIClient(
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: configuration),
            interceptors: interceptors
        )
    }
}

// MARK: - Interceptors

final class InterceptorTests: XCTestCase {
    private let request = URLRequest(url: URL(string: "https://api.test/x")!)

    func testAuthRefreshesOnceOn401ThenSucceeds() async throws {
        let tokens = StubTokens(access: "old", refreshed: "new")
        let seen = Recorder<String?>()
        let interceptor = AuthInterceptor(tokens: tokens)

        let result = try await interceptor.intercept(request) { request in
            let header = request.value(forHTTPHeaderField: "Authorization")
            await seen.append(header)
            return (Data(), response(header == "Bearer new" ? 200 : 401))
        }

        XCTAssertEqual(result.1.statusCode, 200)
        let headers = await seen.values
        XCTAssertEqual(headers, ["Bearer old", "Bearer new"])
    }

    func testAuthThrowsUnauthorizedWhenStill401() async {
        let interceptor = AuthInterceptor(tokens: StubTokens(access: "old", refreshed: "new"))
        await assertThrows(.unauthorized) {
            try await interceptor.intercept(self.request) { _ in (Data(), response(401)) }
        }
    }

    func testRetryRetriesServerErrorsThenReturns() async throws {
        let calls = Recorder<Int>()
        let interceptor = RetryInterceptor(maxAttempts: 3, baseDelay: .zero)

        let result = try await interceptor.intercept(request) { _ in
            await calls.append(1)
            let count = await calls.values.count
            return (Data(), response(count < 3 ? 503 : 200))
        }

        XCTAssertEqual(result.1.statusCode, 200)
        let count = await calls.values.count
        XCTAssertEqual(count, 3)
    }

    func testRetryStopsAtMaxAttempts() async throws {
        let calls = Recorder<Int>()
        let interceptor = RetryInterceptor(maxAttempts: 2, baseDelay: .zero)

        let result = try await interceptor.intercept(request) { _ in
            await calls.append(1)
            return (Data(), response(500))
        }

        XCTAssertEqual(result.1.statusCode, 500)
        let count = await calls.values.count
        XCTAssertEqual(count, 2)
    }

    func testRetryDoesNotRetryOffline() async {
        let calls = Recorder<Int>()
        let interceptor = RetryInterceptor(maxAttempts: 3, baseDelay: .zero)

        await assertThrows(.network(.offline)) {
            try await interceptor.intercept(self.request) { _ in
                await calls.append(1)
                throw TitanError.network(.offline)
            }
        }
        let count = await calls.values.count
        XCTAssertEqual(count, 1)
    }

    func testLoggingInterceptorLogsStatus() async throws {
        let logger = MockLogger()
        let interceptor = LoggingInterceptor(logger: logger)
        _ = try await interceptor.intercept(request) { _ in (Data(), response(404)) }

        XCTAssertEqual(logger.entries.count, 1)
        XCTAssertEqual(logger.entries.first?.level, .warning)
        XCTAssertTrue(logger.entries.first?.message.contains("404") ?? false)
    }
}

// MARK: - Mock and monitor

final class MockAPIClientTests: XCTestCase {
    func testReturnsStubAndRecordsPath() async throws {
        let api = MockAPIClient()
        api.stub(GetProfile.self, with: .success(User(id: 1, displayName: "A")))

        let user = try await api.send(GetProfile())

        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(api.sentPaths, ["/v1/me"])
    }

    func testMissingStubThrows() async {
        let api = MockAPIClient()
        do {
            _ = try await api.send(GetProfile())
            XCTFail("Expected an error")
        } catch {
            guard case .unknown = error else { return XCTFail("Got \(error)") }
        }
    }
}

@MainActor
final class NetworkMonitorTests: XCTestCase {
    func testFixedStateWhenNotMonitoring() {
        XCTAssertFalse(NetworkMonitor(startMonitoring: false, isOnline: false).isOnline)
        XCTAssertTrue(NetworkMonitor(startMonitoring: false).isOnline)
    }
}

// MARK: - Helpers

private func response(_ status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://api.test")!, statusCode: status, httpVersion: nil, headerFields: nil)!
}

private func assertThrows<T>(
    _ expected: TitanError,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> T
) async {
    do {
        _ = try await body()
        XCTFail("Expected \(expected)", file: file, line: line)
    } catch {
        XCTAssertEqual(error as? TitanError, expected, file: file, line: line)
    }
}

private actor Recorder<Value: Sendable> {
    private(set) var values: [Value] = []
    func append(_ value: Value) { values.append(value) }
}

private struct StubTokens: TokenProvider {
    let access: String?
    var refreshed: String = "refreshed"

    func accessToken() async -> String? { access }
    func refreshToken() async throws -> String { refreshed }
}

/// Answers URLSession requests from `handler` instead of the network.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, data) = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
