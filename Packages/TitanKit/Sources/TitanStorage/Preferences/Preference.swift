import SwiftUI

/// A typed UserDefaults key with its default value. Apps declare their keys as static members.
public struct PreferenceKey<Value: Codable & Sendable>: Sendable {
    public let name: String
    public let defaultValue: Value

    public init(_ name: String, default defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// Typed UserDefaults access for ViewModels and services.
public struct Preferences: @unchecked Sendable {
    // @unchecked: UserDefaults is documented as thread-safe.
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func value<Value>(_ key: PreferenceKey<Value>) -> Value {
        guard let data = defaults.data(forKey: key.name),
              let value = try? JSONDecoder().decode(Value.self, from: data)
        else { return key.defaultValue }
        return value
    }

    public func set<Value>(_ value: Value, for key: PreferenceKey<Value>) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key.name)
    }

    public func reset<Value>(_ key: PreferenceKey<Value>) {
        defaults.removeObject(forKey: key.name)
    }
}

/// Property wrapper for views: `@Preference(.hasSeenOnboarding) var seen`.
/// Backed by AppStorage, so the view refreshes when the value changes.
@propertyWrapper
public struct Preference<Value: Codable & Sendable>: DynamicProperty {
    @AppStorage private var raw: Data?
    private let key: PreferenceKey<Value>

    public init(_ key: PreferenceKey<Value>, store: UserDefaults = .standard) {
        self.key = key
        self._raw = AppStorage(key.name, store: store)
    }

    public var wrappedValue: Value {
        get {
            guard let raw, let value = try? JSONDecoder().decode(Value.self, from: raw) else {
                return key.defaultValue
            }
            return value
        }
        nonmutating set {
            raw = try? JSONEncoder().encode(newValue)
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}
