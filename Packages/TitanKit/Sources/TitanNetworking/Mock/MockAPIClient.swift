import Foundation
import TitanCore

/// APIClient for tests and previews: returns stubbed results per endpoint type
/// and records every path that was sent.
public final class MockAPIClient: APIClient, @unchecked Sendable {
    // @unchecked: all mutable state is guarded by `lock`.
    private let lock = NSLock()
    private var stubs: [ObjectIdentifier: Any] = [:]
    private var paths: [String] = []

    public init() {}

    public func stub<E: Endpoint>(_ type: E.Type, with result: Result<E.Response, TitanError>) {
        lock.withLock { stubs[ObjectIdentifier(type)] = result }
    }

    public var sentPaths: [String] {
        lock.withLock { paths }
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws(TitanError) -> E.Response {
        let stored = lock.withLock {
            paths.append(endpoint.path)
            return stubs[ObjectIdentifier(E.self)]
        }
        guard let result = stored as? Result<E.Response, TitanError> else {
            throw .unknown("No stub for \(E.self)")
        }
        switch result {
        case let .success(response): return response
        case let .failure(error): throw error
        }
    }
}
