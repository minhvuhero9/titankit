import Foundation

/// The only error type a kit module hands to the outside.
/// Repositories convert everything else into it, so screens handle one type.
public enum TitanError: Error, Equatable, Sendable {
    case network(NetworkReason)
    case unauthorized
    case decoding(String)
    case notFound
    case storage(String)
    case cancelled
    case unknown(String)

    /// Short message that can be shown to the user as is.
    /// Moves to TitanLocalization string catalogs in phase 3.
    public var userMessage: String {
        switch self {
        case .network(.offline): "Không có kết nối mạng. Hãy kiểm tra Wi-Fi hoặc 4G."
        case .network(.timeout): "Máy chủ phản hồi quá lâu. Hãy thử lại."
        case .network(.server): "Máy chủ đang gặp sự cố. Hãy thử lại sau."
        case .unauthorized: "Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại."
        case .decoding: "Dữ liệu nhận được không hợp lệ."
        case .notFound: "Không tìm thấy nội dung."
        case .storage: "Không lưu được dữ liệu trên máy."
        case .cancelled: "Đã hủy."
        case .unknown: "Đã có lỗi xảy ra. Hãy thử lại."
        }
    }

    /// True when trying the same call again may succeed.
    public var isRetryable: Bool {
        if case .network = self { return true }
        return false
    }
}

public enum NetworkReason: Equatable, Sendable {
    case offline
    case timeout
    case server(statusCode: Int)
}
