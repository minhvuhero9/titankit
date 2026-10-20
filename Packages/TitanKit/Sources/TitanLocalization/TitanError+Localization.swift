import TitanCore

public extension TitanError {
    /// Kit string key for `userMessage`, so the message follows the in-app language.
    var messageKey: String {
        switch self {
        case .network(.offline): "kit.error.offline"
        case .network(.timeout): "kit.error.timeout"
        case .network(.server): "kit.error.server"
        case .unauthorized: "kit.error.unauthorized"
        case .decoding: "kit.error.decoding"
        case .notFound: "kit.error.notFound"
        case .storage: "kit.error.storage"
        case .cancelled: "kit.error.cancelled"
        case .unknown: "kit.error.unknown"
        }
    }
}
