import Foundation
import TitanCore

/// Retries timeouts, dropped connections and 5xx with exponential backoff (baseDelay * 2^attempt).
public struct RetryInterceptor: Interceptor {
    private let maxAttempts: Int
    private let baseDelay: Duration

    public init(maxAttempts: Int = 3, baseDelay: Duration = .milliseconds(500)) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
    }

    public func intercept(_ request: URLRequest, next: RequestHandler) async throws -> (Data, HTTPURLResponse) {
        var attempt = 0
        while true {
            let isLastAttempt = attempt == maxAttempts - 1
            do {
                let result = try await next(request)
                if (500..<600).contains(result.1.statusCode), !isLastAttempt {
                    try await wait(after: attempt)
                    attempt += 1
                    continue
                }
                return result
            } catch let error as TitanError where Self.shouldRetry(error) && !isLastAttempt {
                try await wait(after: attempt)
                attempt += 1
            }
        }
    }

    /// Offline is not retried: the request would fail again right away.
    static func shouldRetry(_ error: TitanError) -> Bool {
        switch error {
        case .network(.timeout), .network(.server): true
        default: false
        }
    }

    private func wait(after attempt: Int) async throws {
        let delay = baseDelay * (1 << attempt)
        guard delay > .zero else { return }
        try await Task.sleep(for: delay)
    }
}
