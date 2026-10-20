import Foundation
import TitanCore

/// Adds the bearer token. On 401 it refreshes once and retries; a second 401 means signed out.
public struct AuthInterceptor: Interceptor {
    private let tokens: any TokenProvider

    public init(tokens: any TokenProvider) {
        self.tokens = tokens
    }

    public var appliesOnlyToAuthenticatedRequests: Bool { true }

    public func intercept(_ request: URLRequest, next: RequestHandler) async throws -> (Data, HTTPURLResponse) {
        var request = request
        if let token = await tokens.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let first = try await next(request)
        guard first.1.statusCode == 401 else { return first }

        let fresh: String
        do {
            fresh = try await tokens.refreshToken()
        } catch {
            throw TitanError.unauthorized
        }
        request.setValue("Bearer \(fresh)", forHTTPHeaderField: "Authorization")

        let second = try await next(request)
        if second.1.statusCode == 401 { throw TitanError.unauthorized }
        return second
    }
}
