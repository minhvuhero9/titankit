import Foundation
import TitanCore
import UIKit

/// In-memory SecureStore for tests and previews. Behaves like the Keychain without touching it.
public final class InMemorySecureStore: SecureStore, @unchecked Sendable {
    // @unchecked: `items` is guarded by `lock`.
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    public init() {}

    public func set(_ data: Data, for key: String) throws(TitanError) {
        lock.withLock { items[key] = data }
    }

    public func data(for key: String) throws(TitanError) -> Data? {
        lock.withLock { items[key] }
    }

    public func remove(_ key: String) throws(TitanError) {
        _ = lock.withLock { items.removeValue(forKey: key) }
    }
}

/// In-memory DataCache with the same expiry rules as FileCache.
public actor InMemoryDataCache: DataCache {
    private var items: [String: (data: Data, expiresAt: Date?)] = [:]

    public init() {}

    public func save<T: Codable & Sendable>(_ value: T, for key: String, ttl: Duration?) async throws(TitanError) {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw .storage("InMemoryDataCache save \(key): \(error)")
        }
        items[key] = (data, ttl.map { Date().addingTimeInterval($0.timeInterval) })
    }

    public func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws(TitanError) -> T? {
        guard let item = items[key] else { return nil }
        if let expiresAt = item.expiresAt, expiresAt <= Date() {
            items[key] = nil
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: item.data)
        } catch {
            throw .decoding("InMemoryDataCache load \(key): \(error)")
        }
    }

    public func remove(_ key: String) async {
        items[key] = nil
    }

    public func clear() async {
        items.removeAll()
    }
}

/// Returns the same image for every URL, instantly. For previews and snapshot tests.
public final class MockImageCache: ImageCache, @unchecked Sendable {
    // @unchecked: `requested` is guarded by `lock`; UIImage is immutable.
    private let image: UIImage
    private let lock = NSLock()
    private var requested: [URL] = []

    public init(image: UIImage = UIImage(systemName: "photo") ?? UIImage()) {
        self.image = image
    }

    public var requestedURLs: [URL] {
        lock.withLock { requested }
    }

    public func image(for url: URL) async throws(TitanError) -> UIImage {
        lock.withLock { requested.append(url) }
        return image
    }

    public func prefetch(_ urls: [URL]) {}

    public func clearMemory() {}
}
