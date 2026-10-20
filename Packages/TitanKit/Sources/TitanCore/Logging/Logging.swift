import Foundation

public enum LogLevel: Int, Comparable, Sendable, CaseIterable {
    case debug, info, warning, error

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Strategy for writing logs. Pick OSLogger in apps, MockLogger in tests, NoopLogger to silence.
public protocol Logging: Sendable {
    func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, line: Int)
}

public extension Logging {
    func debug(_ message: @autoclosure () -> String, file: String = #fileID, line: Int = #line) {
        log(.debug, message(), file: file, line: line)
    }

    func info(_ message: @autoclosure () -> String, file: String = #fileID, line: Int = #line) {
        log(.info, message(), file: file, line: line)
    }

    func warning(_ message: @autoclosure () -> String, file: String = #fileID, line: Int = #line) {
        log(.warning, message(), file: file, line: line)
    }

    func error(_ message: @autoclosure () -> String, file: String = #fileID, line: Int = #line) {
        log(.error, message(), file: file, line: line)
    }
}

public struct NoopLogger: Logging {
    public init() {}

    public func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, line: Int) {}
}
