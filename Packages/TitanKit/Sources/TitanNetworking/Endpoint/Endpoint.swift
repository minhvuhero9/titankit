import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
}

/// Describes one request and the type it decodes into. Apps declare one small struct per call.
public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable

    var path: String { get }
    var method: HTTPMethod { get }
    var query: [String: String] { get }
    var headers: [String: String] { get }
    var body: (any Encodable & Sendable)? { get }
    /// When false, AuthInterceptor skips this request (login, public config...).
    var requiresAuth: Bool { get }
}

public extension Endpoint {
    var method: HTTPMethod { .get }
    var query: [String: String] { [:] }
    var headers: [String: String] { [:] }
    var body: (any Encodable & Sendable)? { nil }
    var requiresAuth: Bool { true }
}

/// Response type for calls whose body is empty or ignored (204, fire-and-forget).
public struct EmptyResponse: Decodable, Equatable, Sendable {
    public init() {}
}
