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

    /// - Parameter accounts: email → password pairs that can sign in.
    public init(accounts: [String: String] = ["demo@titan.app": "123456"], signedIn: AuthUser? = nil, delay: Duration = .zero) {
        self.accounts = accounts.reduce(into: [:]) { result, pair in
            result[pair.key.lowercased()] = (pair.value, AuthUser(id: UUID().uuidString, email: pair.key.lowercased(), provider: .email))
        }
        self.signedIn = signedIn
        self.delay = delay
    }

    public func fail(next error: TitanError) {
        nextError = error
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

    public func signOut() async throws(TitanError) {
        try await prepare()
        signedIn = nil
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
