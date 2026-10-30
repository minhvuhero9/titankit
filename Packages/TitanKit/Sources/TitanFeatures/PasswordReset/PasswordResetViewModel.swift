import Foundation
import TitanAuth
import TitanCore
import TitanLocalization

/// Forgot password in four steps: the email, the code sent to it, a new password twice, then
/// "You're all set" which signs in with the new password. With `sendsLink`, for backends that
/// email a reset link instead of a code (Firebase), it stops at "Check your email".
@MainActor
public final class PasswordResetViewModel: ObservableObject {
    public enum Step: Int, CaseIterable, Sendable {
        case email, code, password, done
        /// The reset link is on its way; the password is changed from the email.
        case linkSent
    }

    @Published public private(set) var step: Step = .email
    @Published public var email: String
    /// Typing again clears the "wrong code" state.
    @Published public var code = "" {
        didSet { if code != oldValue { isCodeWrong = false } }
    }
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public private(set) var isLoading = false
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?
    /// Kit string key of a short confirmation, e.g. "a new code is on its way".
    @Published public private(set) var noticeKey: String?
    @Published public private(set) var isCodeWrong = false
    /// Set when the user taps Continue, so errors don't show while typing the first time.
    @Published public private(set) var hasTriedStep = false
    /// When "Resend code" becomes available.
    @Published public private(set) var resendAvailableAt: Date = .distantPast

    public let codeLength: Int
    public let resendDelay: TimeInterval
    /// The backend emails a link rather than a code.
    public let sendsLink: Bool
    private let auth: any AuthService
    private let now: () -> Date
    private var token: String?

    /// - Parameters:
    ///   - email: fills in the first step, e.g. what was typed on the sign-in screen.
    ///   - codeLength: digits in the emailed code.
    ///   - resendDelay: seconds before the code can be sent again.
    public init(
        auth: any AuthService,
        email: String = "",
        codeLength: Int = 4,
        resendDelay: TimeInterval = 60,
        sendsLink: Bool = false,
        now: @escaping () -> Date = Date.init
    ) {
        self.auth = auth
        self.email = email
        self.codeLength = codeLength
        self.resendDelay = resendDelay
        self.sendsLink = sendsLink
        self.now = now
    }

    public var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespaces)
    }

    public var canContinue: Bool {
        guard !isLoading else { return false }
        switch step {
        case .email: return !email.isBlank
        case .code: return code.count == codeLength
        case .password: return !password.isEmpty && !confirmPassword.isEmpty
        case .done, .linkSent: return true
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

    /// Seconds left before the code can be sent again; 0 when it can.
    public func secondsUntilResend(at date: Date) -> Int {
        max(0, Int(resendAvailableAt.timeIntervalSince(date).rounded(.up)))
    }

    /// Continue on the current step. Returns the signed-in user after the last step.
    public func next() async -> AuthUser? {
        guard canContinue else { return nil }
        hasTriedStep = true
        errorKey = nil
        noticeKey = nil
        switch step {
        case .email:
            guard emailErrorKey == nil else { return nil }
            if await sendCode() { move(to: sendsLink ? .linkSent : .code) }
        case .code:
            await verifyCode()
        case .password:
            guard passwordErrorKey == nil, confirmErrorKey == nil else { return nil }
            await saveNewPassword()
        case .done:
            return await signIn()
        case .linkSent:
            break
        }
        return nil
    }

    /// Sends the code again once the countdown is over.
    public func resend() async {
        guard step == .code || step == .linkSent, !isLoading, secondsUntilResend(at: now()) == 0 else { return }
        errorKey = nil
        noticeKey = nil
        if await sendCode() {
            code = ""
            noticeKey = KitStrings.PasswordReset.codeSent
        }
    }

    /// Back: the previous step. False on the first and last steps, where back leaves the flow.
    public func back() -> Bool {
        guard !isLoading else { return false }
        switch step {
        case .email, .done:
            return false
        case .code, .linkSent:
            move(to: .email)
        case .password:
            token = nil
            code = ""
            move(to: .code)
        }
        return true
    }

    private func move(to step: Step) {
        self.step = step
        hasTriedStep = false
    }

    private func sendCode() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.sendPasswordReset(email: trimmedEmail)
            resendAvailableAt = now().addingTimeInterval(resendDelay)
            return true
        } catch {
            errorKey = Self.messageKey(for: error)
            return false
        }
    }

    private func verifyCode() async {
        isLoading = true
        defer { isLoading = false }
        do {
            token = try await auth.verifyPasswordResetCode(email: trimmedEmail, code: code)
            move(to: .password)
        } catch {
            if error == .unauthorized {
                code = ""
                isCodeWrong = true
            }
            errorKey = Self.messageKey(for: error)
        }
    }

    private func saveNewPassword() async {
        guard let token else {
            move(to: .code)
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.resetPassword(token: token, newPassword: password)
            self.token = nil
            move(to: .done)
        } catch {
            errorKey = Self.messageKey(for: error)
            // The code has expired: ask for it again.
            if error == .unauthorized {
                self.token = nil
                code = ""
                move(to: .code)
            }
        }
    }

    private func signIn() async -> AuthUser? {
        isLoading = true
        defer { isLoading = false }
        do {
            return try await auth.signIn(.email(email: trimmedEmail, password: password))
        } catch {
            errorKey = Self.messageKey(for: error)
            return nil
        }
    }

    static func messageKey(for error: TitanError) -> String? {
        switch error {
        case .cancelled: nil
        case .unauthorized: KitStrings.PasswordReset.wrongCode
        default: error.messageKey
        }
    }
}
