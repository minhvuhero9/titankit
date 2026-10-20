import Foundation
import TitanAuth
import TitanCore
import TitanLocalization

/// Email sign-in form state. Social sign-in is handled by the app through LoginConfig.
@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public private(set) var isLoading = false
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?
    /// Set after the user leaves a field, so errors don't show while typing the first time.
    @Published public var hasTriedSubmit = false

    private let auth: any AuthService

    public init(auth: any AuthService) {
        self.auth = auth
    }

    public var emailErrorKey: String? {
        guard hasTriedSubmit, !Credentials.isValidEmail(email) else { return nil }
        return KitStrings.Login.invalidEmail
    }

    public var passwordErrorKey: String? {
        guard hasTriedSubmit, !Credentials.isValidPassword(password) else { return nil }
        return KitStrings.Login.shortPassword
    }

    public var canSubmit: Bool {
        !email.isBlank && !password.isEmpty && !isLoading
    }

    /// Returns the user on success; nil when the form is invalid or sign-in failed (see `errorKey`).
    public func signIn() async -> AuthUser? {
        hasTriedSubmit = true
        errorKey = nil
        guard Credentials.isValidEmail(email), Credentials.isValidPassword(password) else { return nil }

        isLoading = true
        defer { isLoading = false }
        do {
            let trimmed = email.trimmingCharacters(in: .whitespaces)
            return try await auth.signIn(.email(email: trimmed, password: password))
        } catch {
            errorKey = Self.messageKey(for: error)
            return nil
        }
    }

    public func clearError() {
        errorKey = nil
    }

    static func messageKey(for error: TitanError) -> String? {
        switch error {
        case .cancelled: nil
        case .unauthorized: KitStrings.Login.invalidCredentials
        default: error.messageKey
        }
    }
}
