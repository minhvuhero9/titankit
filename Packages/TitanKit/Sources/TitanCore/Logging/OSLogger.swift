import os

/// Writes to the unified log, visible in Xcode and Console.app.
public struct OSLogger: Logging {
    private let logger: os.Logger
    private let minLevel: LogLevel

    public init(subsystem: String, category: String = "app", minLevel: LogLevel) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
        self.minLevel = minLevel
    }

    public func log(_ level: LogLevel, _ message: @autoclosure () -> String, file: String, line: Int) {
        guard level >= minLevel else { return }
        let text = "\(file):\(line) \(message())"
        switch level {
        case .debug: logger.debug("\(text, privacy: .public)")
        case .info: logger.info("\(text, privacy: .public)")
        case .warning: logger.warning("\(text, privacy: .public)")
        case .error: logger.error("\(text, privacy: .public)")
        }
    }
}
