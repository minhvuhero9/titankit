import Foundation

/// Keeps every log line in memory so tests can assert on them.
public final class MockLogger: Logging, @unchecked Sendable {
    public struct Entry: Equatable, Sendable {
        public let level: LogLevel
        public let message: String
    }

    private let lock = NSLock()
    private var storage: [Entry] = []

    public init() {}

    public var entries: [Entry] {
        lock.withLock { storage }
    }

    public func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, line: Int) {
        let entry = Entry(level: level, message: message())
        lock.withLock { storage.append(entry) }
    }
}
