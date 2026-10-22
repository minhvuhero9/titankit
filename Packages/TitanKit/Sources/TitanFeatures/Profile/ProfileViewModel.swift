import Foundation
import TitanAuth
import TitanCore
import TitanLocalization

/// Loads the signed-in user and saves a new display name.
@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public private(set) var user: AuthUser?
    @Published public var name = ""
    @Published public private(set) var isSaving = false
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?

    private let auth: any AuthService

    public init(auth: any AuthService) {
        self.auth = auth
    }

    public func load() async {
        user = await auth.currentUser()
        name = user?.displayName ?? ""
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True once the name differs from the saved one and isn't blank.
    public var canSave: Bool {
        user != nil && !trimmedName.isEmpty && trimmedName != (user?.displayName ?? "") && !isSaving
    }

    /// Returns the updated user, or nil when saving failed (see `errorKey`).
    public func save() async -> AuthUser? {
        guard canSave else { return nil }
        errorKey = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await auth.updateProfile(displayName: trimmedName)
            user = updated
            name = updated.displayName ?? ""
            return updated
        } catch {
            errorKey = error == .cancelled ? nil : error.messageKey
            return nil
        }
    }
}
