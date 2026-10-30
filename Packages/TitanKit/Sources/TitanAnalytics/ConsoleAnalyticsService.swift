import Foundation
import TitanCore

/// Writes events to the log and stops on a badly named event in Debug, so a wrong name shows up
/// the first time it is sent instead of in the dashboard weeks later.
public struct ConsoleAnalyticsService: AnalyticsService {
    private let logger: any Logging

    public init(logger: any Logging) {
        self.logger = logger
    }

    public func track(_ event: AnalyticsEvent) {
        assert(AnalyticsEvent.isValidName(event.name), "Analytics event name \"\(event.name)\" is not snake_case ≤ 40")
        let parameters = event.parameters.keys.sorted().map { "\($0)=\(Self.describe(event.parameters[$0]))" }
        logger.debug("📊 \(event.name) \(parameters.joined(separator: " "))")
    }

    public func screen(_ name: String) { logger.debug("📊 screen \(name)") }
    public func setUserId(_ id: String?) { logger.debug("📊 user \(id ?? "nil")") }
    public func setUserProperty(_ value: String?, for key: String) { logger.debug("📊 \(key)=\(value ?? "nil")") }
    public func setCollectionEnabled(_ enabled: Bool) { logger.debug("📊 collection \(enabled ? "on" : "off")") }

    private static func describe(_ value: AnalyticsValue?) -> String {
        switch value {
        case let .string(text)?: text
        case let .int(number)?: String(number)
        case let .double(number)?: String(number)
        case let .bool(flag)?: String(flag)
        case nil: ""
        }
    }
}
