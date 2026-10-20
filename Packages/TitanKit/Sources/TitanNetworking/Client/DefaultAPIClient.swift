import Foundation
import TitanCore

/// URLSession-based client: builds the request, runs it through the interceptors,
/// checks the status code and decodes the response. Every failure becomes a TitanError.
public final class DefaultAPIClient: APIClient, @unchecked Sendable {
    // @unchecked: all stored properties are immutable after init, and JSONDecoder/JSONEncoder
    // are only read (decode/encode are safe to call concurrently).
    private let baseURL: URL
    private let session: URLSession
    private let interceptors: [any Interceptor]
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        interceptors: [any Interceptor] = [],
        decoder: JSONDecoder = .titan,
        encoder: JSONEncoder = .titan
    ) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
        self.decoder = decoder
        self.encoder = encoder
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws(TitanError) -> E.Response {
        let request = try makeRequest(for: endpoint)
        let handler = chain(requiresAuth: endpoint.requiresAuth)

        let result: (data: Data, response: HTTPURLResponse)
        do {
            result = try await handler(request)
        } catch let error as TitanError {
            throw error
        } catch {
            throw Self.map(error)
        }

        try Self.validate(statusCode: result.response.statusCode)

        if E.Response.self == EmptyResponse.self, let empty = EmptyResponse() as? E.Response {
            return empty
        }
        do {
            return try decoder.decode(E.Response.self, from: result.data)
        } catch {
            throw .decoding(String(describing: error))
        }
    }

    // MARK: - Request

    func makeRequest<E: Endpoint>(for endpoint: E) throws(TitanError) -> URLRequest {
        let url = baseURL.appending(path: endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw .unknown("Invalid URL for path \(endpoint.path)")
        }
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let finalURL = components.url else {
            throw .unknown("Invalid query for path \(endpoint.path)")
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw .unknown("Could not encode body: \(error)")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    // MARK: - Chain

    private func chain(requiresAuth: Bool) -> RequestHandler {
        let session = session
        var next: RequestHandler = { request in
            let result: (Data, URLResponse)
            do {
                result = try await session.data(for: request)
            } catch {
                throw DefaultAPIClient.map(error)
            }
            guard let http = result.1 as? HTTPURLResponse else {
                throw TitanError.unknown("Response is not HTTP")
            }
            return (result.0, http)
        }
        let active = interceptors.filter { requiresAuth || !$0.appliesOnlyToAuthenticatedRequests }
        for interceptor in active.reversed() {
            let current = next
            next = { request in try await interceptor.intercept(request, next: current) }
        }
        return next
    }

    // MARK: - Errors

    static func validate(statusCode: Int) throws(TitanError) {
        switch statusCode {
        case 200..<300: return
        case 401: throw .unauthorized
        case 404: throw .notFound
        default: throw .network(.server(statusCode: statusCode))
        }
    }

    static func map(_ error: any Error) -> TitanError {
        if error is CancellationError { return .cancelled }
        guard let urlError = error as? URLError else { return .unknown(String(describing: error)) }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .network(.offline)
        case .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return .network(.timeout)
        case .cancelled:
            return .cancelled
        default:
            return .unknown(urlError.localizedDescription)
        }
    }
}
