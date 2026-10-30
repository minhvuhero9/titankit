import FirebaseAuth
import Foundation
import TitanAuth
import TitanCore

/// `AuthService` on Firebase Authentication: email and password, Apple, Google and guest.
/// Call `FirebaseBootstrap.configure` before creating it.
///
/// Firebase emails a reset link rather than a code: show `PasswordResetScreen(sendsLink: true)`.
/// `verifyPasswordResetCode` and `resetPassword` take the link's `oobCode`, for an app that
/// opens the link itself.
public struct FirebaseAuthService: AuthService {
    public init() {}

    private var auth: Auth { Auth.auth() }

    public func currentUser() async -> TitanAuth.AuthUser? {
        auth.currentUser.map(Self.user)
    }

    public func signIn(_ method: SignInMethod) async throws(TitanError) -> TitanAuth.AuthUser {
        do {
            let result: AuthDataResult
            switch method {
            case let .email(email, password):
                result = try await auth.signIn(withEmail: email, password: password)
            case let .apple(idToken, rawNonce, fullName):
                let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: rawNonce,
                                                               fullName: fullName)
                result = try await auth.signIn(with: credential)
                // Apple gives the name only the first time; keep it on the Firebase user.
                if result.user.displayName == nil, let name = fullName.flatMap(Self.displayName) {
                    let change = result.user.createProfileChangeRequest()
                    change.displayName = name
                    try? await change.commitChanges()
                }
            case let .google(idToken, accessToken):
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                result = try await auth.signIn(with: credential)
            case .anonymous:
                result = try await auth.signInAnonymously()
            }
            return Self.user(auth.currentUser ?? result.user)
        } catch {
            throw Self.map(error)
        }
    }

    public func signUp(email: String, password: String, displayName: String?) async throws(TitanError) -> TitanAuth.AuthUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            if let displayName, !displayName.isEmpty {
                let change = result.user.createProfileChangeRequest()
                change.displayName = displayName
                try await change.commitChanges()
            }
            return Self.user(auth.currentUser ?? result.user)
        } catch {
            throw Self.map(error)
        }
    }

    public func sendPasswordReset(email: String) async throws(TitanError) {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            // Don't reveal whether an account uses this address.
            if (error as NSError).code == AuthErrorCode.userNotFound.rawValue { return }
            throw Self.map(error)
        }
    }

    public func verifyPasswordResetCode(email: String, code: String) async throws(TitanError) -> String {
        do {
            _ = try await auth.verifyPasswordResetCode(code)
            return code
        } catch {
            throw Self.map(error)
        }
    }

    public func resetPassword(token: String, newPassword: String) async throws(TitanError) {
        do {
            try await auth.confirmPasswordReset(withCode: token, newPassword: newPassword)
        } catch {
            throw Self.map(error)
        }
    }

    public func updateProfile(displayName: String) async throws(TitanError) -> TitanAuth.AuthUser {
        guard let user = auth.currentUser else { throw .unauthorized }
        do {
            let change = user.createProfileChangeRequest()
            change.displayName = displayName
            try await change.commitChanges()
            return Self.user(auth.currentUser ?? user)
        } catch {
            throw Self.map(error)
        }
    }

    public func signOut() async throws(TitanError) {
        do {
            try auth.signOut()
        } catch {
            throw Self.map(error)
        }
    }

    public func idToken(forceRefresh: Bool) async throws(TitanError) -> String {
        guard let user = auth.currentUser else { throw .unauthorized }
        do {
            return try await user.getIDToken(forcingRefresh: forceRefresh)
        } catch {
            throw Self.map(error)
        }
    }

    /// Throws `.unauthorized` when Firebase wants a recent sign-in first.
    public func deleteAccount() async throws(TitanError) {
        guard let user = auth.currentUser else { throw .unauthorized }
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                user.delete { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw Self.map(error)
        }
    }

    // MARK: - Mapping

    static func user(_ user: User) -> TitanAuth.AuthUser {
        TitanAuth.AuthUser(
            id: user.uid,
            email: user.email,
            displayName: user.displayName,
            provider: user.isAnonymous ? .anonymous : provider(for: user.providerData.first?.providerID),
            isAnonymous: user.isAnonymous
        )
    }

    static func provider(for providerID: String?) -> TitanAuth.AuthProvider {
        switch providerID {
        case "apple.com": .apple
        case "google.com": .google
        case "facebook.com": .facebook
        default: .email
        }
    }

    static func displayName(_ components: PersonNameComponents) -> String? {
        let name = PersonNameComponentsFormatter().string(from: components)
        return name.isEmpty ? nil : name
    }

    /// Firebase errors to the kit's: wrong credentials and stale sessions become `.unauthorized`
    /// so the screens show their usual messages.
    static func map(_ error: any Error) -> TitanError {
        let nsError = error as NSError
        guard nsError.domain == AuthErrors.domain, let code = AuthErrorCode(rawValue: nsError.code) else {
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet { return .network(.offline) }
            return .unknown(error.localizedDescription)
        }
        switch code {
        case .wrongPassword, .invalidCredential, .userNotFound, .requiresRecentLogin, .userDisabled,
             .expiredActionCode, .invalidActionCode:
            return .unauthorized
        case .networkError:
            return .network(.offline)
        case .tooManyRequests:
            return .network(.server(statusCode: 429))
        case .emailAlreadyInUse:
            return .unknown("email already in use")
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
