import Foundation

public typealias RequestHandler = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

/// One link in the request chain (Chain of Responsibility).
/// Change the request, call `next`, then inspect or replace the response.
public protocol Interceptor: Sendable {
    /// True for interceptors that only make sense on authenticated endpoints.
    var appliesOnlyToAuthenticatedRequests: Bool { get }

    func intercept(_ request: URLRequest, next: RequestHandler) async throws -> (Data, HTTPURLResponse)
}

public extension Interceptor {
    var appliesOnlyToAuthenticatedRequests: Bool { false }
}
