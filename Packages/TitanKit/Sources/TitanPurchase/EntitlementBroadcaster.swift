import Foundation

/// Holds the current entitlements and hands each listener its own stream.
/// Shared by the StoreKit and mock services.
public final class EntitlementBroadcaster: @unchecked Sendable {
    // @unchecked: all state is guarded by `lock`.
    private let lock = NSLock()
    private var current: Entitlements
    private var continuations: [UUID: AsyncStream<Entitlements>.Continuation] = [:]

    public init(_ initial: Entitlements = .none) {
        current = initial
    }

    public var value: Entitlements {
        lock.withLock { current }
    }

    public func stream() -> AsyncStream<Entitlements> {
        let (stream, continuation) = AsyncStream.makeStream(of: Entitlements.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        let now = lock.withLock {
            continuations[id] = continuation
            return current
        }
        continuation.yield(now)
        continuation.onTermination = { [weak self] _ in
            self?.lock.withLock { _ = self?.continuations.removeValue(forKey: id) }
        }
        return stream
    }

    /// Sends `entitlements` to every listener, unless nothing changed.
    public func send(_ entitlements: Entitlements) {
        let listeners: [AsyncStream<Entitlements>.Continuation] = lock.withLock {
            guard current != entitlements else { return [] }
            current = entitlements
            return Array(continuations.values)
        }
        listeners.forEach { $0.yield(entitlements) }
    }
}

/// Remembers the last entitlements so the next launch shows premium before StoreKit answers.
public protocol EntitlementCache: Sendable {
    func load() -> Entitlements?
    func save(_ entitlements: Entitlements)
}

public struct UserDefaultsEntitlementCache: EntitlementCache, @unchecked Sendable {
    // @unchecked: UserDefaults is thread safe.
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "titan.purchase.entitlements") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> Entitlements? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(Entitlements.self, from: $0) }
    }

    public func save(_ entitlements: Entitlements) {
        if let data = try? JSONEncoder().encode(entitlements) {
            defaults.set(data, forKey: key)
        }
    }
}
