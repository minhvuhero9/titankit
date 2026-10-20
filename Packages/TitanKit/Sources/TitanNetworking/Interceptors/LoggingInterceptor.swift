import Foundation
import TitanCore

/// Logs method, URL, status and time. Bodies are logged only when asked (never in prod).
public struct LoggingInterceptor: Interceptor {
    private let logger: any Logging
    private let logBodies: Bool

    public init(logger: any Logging, logBodies: Bool = false) {
        self.logger = logger
        self.logBodies = logBodies
    }

    public func intercept(_ request: URLRequest, next: RequestHandler) async throws -> (Data, HTTPURLResponse) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "?"
        let clock = ContinuousClock()
        let start = clock.now

        do {
            let (data, response) = try await next(request)
            let elapsed = clock.now - start
            let level: LogLevel = response.statusCode >= 400 ? .warning : .debug
            logger.log(level, "\(method) \(url) → \(response.statusCode) (\(elapsed))", file: #fileID, line: #line)
            if logBodies, let text = String(data: data, encoding: .utf8) {
                logger.debug("Body: \(text)")
            }
            return (data, response)
        } catch {
            logger.error("\(method) \(url) failed: \(error)")
            throw error
        }
    }
}
