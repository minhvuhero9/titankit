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
            case let .apple(_, _, fullName):
                // Apple and Google always have a credential; only a guest has none.
                // swiftlint:disable:next force_unwrapping
                result = try await auth.signIn(with: Self.credential(for: method)!)
                // Apple gives the name only the first time; keep it on the Firebase user.
                if result.user.displayName == nil, let name = fullName.flatMap(Self.displayName) {
                    let change = result.user.createProfileChangeRequest()
                    change.displayName = name
                    try? await change.commitChanges()
                }
            case .google:
                // Apple and Google always have a credential; only a guest has none.
                // swiftlint:disable:next force_unwrapping
                result = try await auth.signIn(with: Self.credential(for: method)!)
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

    public func linkedProviders() async -> [TitanAuth.AuthProvider] {
        guard let user = auth.currentUser, !user.isAnonymous else { return [] }
        return user.providerData.map { Self.provider(for: $0.providerID) }
    }

    public func link(_ method: SignInMethod) async throws(TitanError) -> TitanAuth.AuthUser {
        guard let user = auth.currentUser else { throw .unauthorized }
        guard let credential = Self.credential(for: method) else { throw .unknown("a guest sign-in can't be linked") }
        do {
            let result = try await user.link(with: credential)
            return Self.user(auth.currentUser ?? result.user)
        } catch {
            throw Self.map(error)
        }
    }

    public func unlink(_ provider: TitanAuth.AuthProvider) async throws(TitanError) -> TitanAuth.AuthUser {
        guard let user = auth.currentUser else { throw .unauthorized }
        let ids = user.providerData.map(\.providerID)
        guard let id = ids.first(where: { Self.provider(for: $0) == provider }) else { throw .notFound }
        guard ids.count > 1 else { throw AuthFailure.lastProvider }
        do {
            return Self.user(try await user.unlink(fromProvider: id))
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

    /// Throws `.unauthorized` when Firebase wants a recent sign-in first. An account that signs in
    /// with Apple shows the Apple sheet once more: the fresh sign-in satisfies Firebase, and its
    /// authorization code revokes the app's Apple tokens, as App Store guideline 5.1.1(v) requires.
    /// Throws `.cancelled` when the user closes that sheet.
    public func deleteAccount() async throws(TitanError) {
        guard let user = auth.currentUser else { throw .unauthorized }
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            try await revokeApple(for: user)
        }
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

    private func revokeApple(for user: User) async throws(TitanError) {
        let authorization = try await AppleSignInHelper().authorize()
        guard let code = authorization.authorizationCode, let credential = Self.credential(for: authorization.method) else {
            throw .unknown("Apple returned no authorization code")
        }
        do {
            try await user.reauthenticate(with: credential)
            try await auth.revokeToken(withAuthorizationCode: code)
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

    /// Firebase's credential for Apple, Google or email; nil for a guest.
    static func credential(for method: SignInMethod) -> AuthCredential? {
        switch method {
        case let .email(email, password):
            return EmailAuthProvider.credential(withEmail: email, password: password)
        case let .apple(idToken, rawNonce, fullName):
            return OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: rawNonce, fullName: fullName)
        case let .google(idToken, accessToken):
            return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        case .anonymous:
            return nil
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
        case .credentialAlreadyInUse, .accountExistsWithDifferentCredential:
            return AuthFailure.credentialInUse
        case .providerAlreadyLinked:
            return AuthFailure.alreadyLinked
        case .noSuchProvider:
            return .notFound
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
