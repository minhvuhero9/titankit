import Foundation
import TitanCore

/// Short-lived storage for Codable values (API responses, drafts). Entries can expire.
public protocol DataCache: Sendable {
    func save<T: Codable & Sendable>(_ value: T, for key: String, ttl: Duration?) async throws(TitanError)
    func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws(TitanError) -> T?
    func remove(_ key: String) async
    func clear() async
}

/// Writes one JSON file per key under Caches/<folder>. The actor serialises file access.
public actor FileCache: DataCache {
    private let directory: URL
    private let fileManager = FileManager.default

    /// `baseDirectory` defaults to the app's Caches folder; tests pass a temporary one.
    public init(folder: String = "TitanCache", baseDirectory: URL? = nil) {
        let base = baseDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = base.appending(path: folder, directoryHint: .isDirectory)
    }

    public func save<T: Codable & Sendable>(_ value: T, for key: String, ttl: Duration?) async throws(TitanError) {
        let entry = Entry(value: value, expiresAt: ttl.map { Date().addingTimeInterval($0.timeInterval) })
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL(for: key), options: .atomic)
        } catch {
            throw .storage("FileCache save \(key): \(error.localizedDescription)")
        }
    }

    public func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws(TitanError) -> T? {
        let url = fileURL(for: key)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let entry: Entry<T>
        do {
            entry = try JSONDecoder().decode(Entry<T>.self, from: Data(contentsOf: url))
        } catch {
            throw .decoding("FileCache load \(key): \(error.localizedDescription)")
        }
        if let expiresAt = entry.expiresAt, expiresAt <= Date() {
            try? fileManager.removeItem(at: url)
            return nil
        }
        return entry.value
    }

    public func remove(_ key: String) async {
        try? fileManager.removeItem(at: fileURL(for: key))
    }

    public func clear() async {
        try? fileManager.removeItem(at: directory)
    }

    /// Keys can contain any character; base64url keeps file names safe.
    private func fileURL(for key: String) -> URL {
        let name = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return directory.appending(path: name + ".json")
    }

    private struct Entry<Value: Codable>: Codable {
        let value: Value
        let expiresAt: Date?
    }
}
