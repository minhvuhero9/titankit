import Foundation

/// A value as the backend stores it, before it is read as a typed key.
public enum RemoteConfigRaw: Equatable, Sendable {
    case bool(Bool)
    case number(Double)
    case string(String)
}

/// A type a `RemoteConfigKey` can hold. Bool, Int, Double and String are built in;
/// a Decodable type opts in with an empty conformance and is read from a JSON string.
public protocol RemoteConfigValue: Sendable {
    /// nil when the stored value can't be read as this type, so the key's default is used.
    static func decode(_ raw: RemoteConfigRaw) -> Self?
}

extension Bool: RemoteConfigValue {
    public static func decode(_ raw: RemoteConfigRaw) -> Bool? {
        switch raw {
        case let .bool(value): value
        case let .number(value): value != 0
        case let .string(value): Bool(value.lowercased())
        }
    }
}

extension Int: RemoteConfigValue {
    public static func decode(_ raw: RemoteConfigRaw) -> Int? {
        switch raw {
        case .bool: nil
        case let .number(value): Int(exactly: value)
        case let .string(value): Int(value)
        }
    }
}

extension Double: RemoteConfigValue {
    public static func decode(_ raw: RemoteConfigRaw) -> Double? {
        switch raw {
        case .bool: nil
        case let .number(value): value
        case let .string(value): Double(value)
        }
    }
}

extension String: RemoteConfigValue {
    public static func decode(_ raw: RemoteConfigRaw) -> String? {
        switch raw {
        case let .string(value): value
        case .bool, .number: nil
        }
    }
}

public extension RemoteConfigValue where Self: Decodable {
    static func decode(_ raw: RemoteConfigRaw) -> Self? {
        guard case let .string(json) = raw, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}
