import Foundation
import TitanAuth
import TitanCore
import TitanLocalization

/// Email sign-up in three steps: name, email, then password twice.
@MainActor
public final class SignUpViewModel: ObservableObject {
    public enum Step: Int, CaseIterable, Sendable {
        case name, email, password
    }

    @Published public private(set) var step: Step = .name
    @Published public var name: String
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public private(set) var isCreating = false
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?
    /// Set when the user taps Continue, so errors don't show while typing the first time.
    @Published public private(set) var hasTriedStep = false

    private let auth: any AuthService

    public init(auth: any AuthService, name: String = "") {
        self.auth = auth
        self.name = name
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var canContinue: Bool {
        guard !isCreating else { return false }
        switch step {
        case .name: return !trimmedName.isEmpty
        case .email: return !email.isBlank
        case .password: return !password.isEmpty && !confirmPassword.isEmpty
        }
    }

    public var emailErrorKey: String? {
        guard hasTriedStep, step == .email, !Credentials.isValidEmail(email) else { return nil }
        return KitStrings.Login.invalidEmail
    }

    public var passwordErrorKey: String? {
        guard hasTriedStep, step == .password, !Credentials.isValidPassword(password) else { return nil }
        return KitStrings.Login.shortPassword
    }

    public var confirmErrorKey: String? {
        guard hasTriedStep, step == .password, confirmPassword != password else { return nil }
        return KitStrings.SignUp.passwordMismatch
    }

    /// Continue: checks the step and moves on. Returns the new user once the account exists.
    public func next() async -> AuthUser? {
        guard canContinue else { return nil }
        hasTriedStep = true
        errorKey = nil
        switch step {
        case .name:
            move(to: .email)
            return nil
        case .email:
            guard emailErrorKey == nil else { return nil }
            move(to: .password)
            return nil
        case .password:
            guard passwordErrorKey == nil, confirmErrorKey == nil else { return nil }
            return await createAccount()
        }
    }

    /// Back: the previous step. False on the first step, where back leaves sign-up.
    public func back() -> Bool {
        guard !isCreating, let previous = Step(rawValue: step.rawValue - 1) else { return false }
        move(to: previous)
        return true
    }

    private func move(to step: Step) {
        self.step = step
        hasTriedStep = false
    }

    private func createAccount() async -> AuthUser? {
        isCreating = true
        defer { isCreating = false }
        do {
            let address = email.trimmingCharacters(in: .whitespaces)
            return try await auth.signUp(email: address, password: password, displayName: trimmedName)
        } catch {
            errorKey = error == .cancelled ? nil : error.messageKey
            return nil
        }
    }
}
