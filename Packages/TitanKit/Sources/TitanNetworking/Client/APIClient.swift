import Foundation
import TitanCore

public protocol APIClient: Sendable {
    func send<E: Endpoint>(_ endpoint: E) async throws(TitanError) -> E.Response
}

/// Gives the access token to AuthInterceptor. Usually implemented by the auth service,
/// so networking never depends on TitanAuth or Firebase directly.
public protocol TokenProvider: Sendable {
    func accessToken() async -> String?
    func refreshToken() async throws -> String
}
