import Foundation
import TitanCore

/// In-memory AuthService for previews, tests and building screens before a backend exists.
public actor MockAuthService: AuthService {
    private var accounts: [String: (password: String, user: AuthUser)]
    private var signedIn: AuthUser?
    /// Thrown by the next call instead of running it, then cleared. Set with `fail(next:)`.
    private var nextError: TitanError?
    public var delay: Duration
    public private(set) var resetRequests: [String] = []
    /// The code every password reset email "contains".
    public let resetCode: String
    /// Reset tokens handed out by `verifyPasswordResetCode`, with their email.
    private var resetTokens: [String: String] = [:]
    /// Ways to sign in added with `link`, by user id.
    private var linked: [String: [AuthProvider]] = [:]
    /// Providers whose credential "belongs to another account": linking them fails.
    private var taken: Set<AuthProvider> = []

    /// - Parameter accounts: email → password pairs that can sign in.
    public init(
        accounts: [String: String] = ["demo@titan.app": "123456"],
        signedIn: AuthUser? = nil,
        delay: Duration = .zero,
        resetCode: String = "1234"
    ) {
        self.accounts = accounts.reduce(into: [:]) { result, pair in
            result[pair.key.lowercased()] = (pair.value, AuthUser(id: UUID().uuidString, email: pair.key.lowercased(), provider: .email))
        }
        self.signedIn = signedIn
        self.delay = delay
        self.resetCode = resetCode
    }

    public func fail(next error: TitanError) {
        nextError = error
    }

    /// Makes `link` with this provider fail as if another account used it.
    public func markTaken(_ provider: AuthProvider) {
        taken.insert(provider)
    }

    public func currentUser() async -> AuthUser? {
        signedIn
    }

    public func signIn(_ method: SignInMethod) async throws(TitanError) -> AuthUser {
        try await prepare()
        let user: AuthUser
        switch method {
        case let .email(email, password):
            guard let account = accounts[email.lowercased()], account.password == password else {
                throw .unauthorized
            }
            user = account.user
        case .apple:
            user = AuthUser(id: "apple-user", email: nil, provider: .apple)
        case .google:
            user = AuthUser(id: "google-user", email: nil, provider: .google)
        case .anonymous:
            user = AuthUser(id: UUID().uuidString, email: nil, provider: .anonymous, isAnonymous: true)
        }
        signedIn = user
        return user
    }

    public func signUp(email: String, password: String, displayName: String?) async throws(TitanError) -> AuthUser {
        try await prepare()
        let key = email.lowercased()
        guard accounts[key] == nil else { throw .unknown("email already in use") }
        let user = AuthUser(id: UUID().uuidString, email: key, displayName: displayName, provider: .email)
        accounts[key] = (password, user)
        signedIn = user
        return user
    }

    public func sendPasswordReset(email: String) async throws(TitanError) {
        try await prepare()
        resetRequests.append(email.lowercased())
    }

    public func verifyPasswordResetCode(email: String, code: String) async throws(TitanError) -> String {
        try await prepare()
        let key = email.lowercased()
        guard resetRequests.contains(key), accounts[key] != nil, code == resetCode else { throw .unauthorized }
        let token = UUID().uuidString
        resetTokens[token] = key
        return token
    }

    public func resetPassword(token: String, newPassword: String) async throws(TitanError) {
        try await prepare()
        guard let key = resetTokens.removeValue(forKey: token), let account = accounts[key] else { throw .unauthorized }
        accounts[key] = (newPassword, account.user)
    }

    public func updateProfile(displayName: String) async throws(TitanError) -> AuthUser {
        try await prepare()
        guard let user = signedIn else { throw .unauthorized }
        let updated = AuthUser(id: user.id, email: user.email, displayName: displayName,
                               provider: user.provider, isAnonymous: user.isAnonymous)
        signedIn = updated
        if let email = user.email?.lowercased(), let account = accounts[email] {
            accounts[email] = (account.password, updated)
        }
        return updated
    }

    public func signOut() async throws(TitanError) {
        try await prepare()
        signedIn = nil
    }

    public func linkedProviders() async -> [AuthProvider] {
        guard let user = signedIn else { return [] }
        return providers(of: user)
    }

    public func link(_ method: SignInMethod) async throws(TitanError) -> AuthUser {
        try await prepare()
        guard let user = signedIn else { throw .unauthorized }
        let provider: AuthProvider
        switch method {
        case .email: provider = .email
        case .apple: provider = .apple
        case .google: provider = .google
        case .anonymous: throw .unknown("a guest sign-in can't be linked")
        }
        var current = providers(of: user)
        if current.contains(provider) { throw AuthFailure.alreadyLinked }
        if taken.contains(provider) { throw AuthFailure.credentialInUse }
        current.append(provider)
        linked[user.id] = current
        let updated = AuthUser(id: user.id, email: user.email, displayName: user.displayName,
                               provider: user.isAnonymous ? provider : user.provider, isAnonymous: false)
        signedIn = updated
        return updated
    }

    public func unlink(_ provider: AuthProvider) async throws(TitanError) -> AuthUser {
        try await prepare()
        guard let user = signedIn else { throw .unauthorized }
        var current = providers(of: user)
        guard current.contains(provider) else { throw .notFound }
        guard current.count > 1 else { throw AuthFailure.lastProvider }
        current.removeAll { $0 == provider }
        linked[user.id] = current
        return user
    }

    private func providers(of user: AuthUser) -> [AuthProvider] {
        linked[user.id] ?? (user.isAnonymous ? [] : [user.provider])
    }

    public func idToken(forceRefresh: Bool) async throws(TitanError) -> String {
        try await prepare()
        guard let user = signedIn else { throw .unauthorized }
        return "mock-token-\(user.id)"
    }

    public func deleteAccount() async throws(TitanError) {
        try await prepare()
        guard let user = signedIn else { throw .unauthorized }
        accounts = accounts.filter { $0.value.user != user }
        signedIn = nil
    }

    private func prepare() async throws(TitanError) {
        if delay > .zero {
            do { try await Task.sleep(for: delay) } catch { throw .cancelled }
        }
        if let error = nextError {
            nextError = nil
            throw error
        }
    }
}
