import Foundation
import Security
import TitanCore

/// Storage for secrets (tokens, passwords). Never put these in UserDefaults.
public protocol SecureStore: Sendable {
    func set(_ data: Data, for key: String) throws(TitanError)
    func data(for key: String) throws(TitanError) -> Data?
    func remove(_ key: String) throws(TitanError)
}

public extension SecureStore {
    func setString(_ value: String, for key: String) throws(TitanError) {
        try set(Data(value.utf8), for: key)
    }

    func string(for key: String) throws(TitanError) -> String? {
        try data(for: key).flatMap { String(data: $0, encoding: .utf8) }
    }
}

/// Facade over the Security framework's generic password items.
public struct KeychainStore: SecureStore {
    private let service: String
    private let accessGroup: String?

    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func set(_ data: Data, for key: String) throws(TitanError) {
        let query = baseQuery(for: key)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw Self.error(addStatus) }
        default:
            throw Self.error(status)
        }
    }

    public func data(for key: String) throws(TitanError) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw Self.error(status)
        }
    }

    public func remove(_ key: String) throws(TitanError) {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw Self.error(status) }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    private static func error(_ status: OSStatus) -> TitanError {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return .storage("Keychain: \(message)")
    }
}
