import Foundation
import TitanAuth
import TitanCore
import TitanLocalization

/// Deletes the account once the user has ticked the confirmation.
@MainActor
public final class DeleteAccountViewModel: ObservableObject {
    @Published public var hasConfirmed = false
    @Published public private(set) var isDeleting = false
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?

    private let auth: any AuthService

    public init(auth: any AuthService) {
        self.auth = auth
    }

    public var canDelete: Bool {
        hasConfirmed && !isDeleting
    }

    /// True when the account is gone.
    public func delete() async -> Bool {
        guard canDelete else { return false }
        errorKey = nil
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await auth.deleteAccount()
            return true
        } catch {
            errorKey = Self.messageKey(for: error)
            return false
        }
    }

    nonisolated static func messageKey(for error: TitanError) -> String? {
        switch error {
        case .cancelled: nil
        case .unauthorized: KitStrings.DeleteAccount.signInAgain
        default: error.messageKey
        }
    }
}
