import Foundation

/// The signed-in user as the app sees it. Adapters convert their own user type into this.
public struct AuthUser: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let email: String?
    public let displayName: String?
    public let provider: AuthProvider
    public let isAnonymous: Bool

    public init(id: String, email: String?, displayName: String? = nil, provider: AuthProvider, isAnonymous: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.provider = provider
        self.isAnonymous = isAnonymous
    }
}

public enum AuthProvider: String, Sendable, Codable, CaseIterable {
    case email, apple, google, facebook, anonymous
}

public enum AuthState: Sendable, Equatable {
    /// Still checking at launch.
    case unknown
    case signedOut
    case signedIn(AuthUser)
}

public enum SignInMethod: Sendable, Equatable {
    case email(email: String, password: String)
    case apple(idToken: String, rawNonce: String, fullName: PersonNameComponents?)
    case google(idToken: String, accessToken: String)
    case anonymous
}

/// Simple checks shared by sign-in and sign-up forms.
public enum Credentials {
    public static let minimumPasswordLength = 6

    public static func isValidEmail(_ email: String) -> Bool {
        let parts = email.trimmingCharacters(in: .whitespaces).split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        guard let dot = domain.lastIndex(of: "."), dot != domain.startIndex else { return false }
        return domain.distance(from: dot, to: domain.endIndex) > 2 && !domain.contains(" ")
    }

    public static func isValidPassword(_ password: String) -> Bool {
        password.count >= minimumPasswordLength
    }
}
