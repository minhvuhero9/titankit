import Foundation
import TitanAuth
import TitanCore
import TitanLocalization

/// Gets a provider's credential, e.g. by showing the Apple or Google sheet.
public typealias CredentialRequest = @MainActor (AuthProvider) async throws(TitanError) -> SignInMethod

/// Which providers can sign in to the account, and linking or unlinking one.
@MainActor
public final class LinkedAccountsViewModel: ObservableObject {
    @Published public private(set) var linked: [AuthProvider] = []
    /// The provider being linked or unlinked.
    @Published public private(set) var busy: AuthProvider?
    /// Kit string key of the last error, shown as a toast.
    @Published public private(set) var errorKey: String?
    /// The provider just linked (true) or unlinked (false), for a confirmation toast.
    @Published public private(set) var lastChange: (provider: AuthProvider, isLinked: Bool)?

    private let auth: any AuthService
    private let credential: CredentialRequest

    public init(auth: any AuthService, credential: @escaping CredentialRequest) {
        self.auth = auth
        self.credential = credential
    }

    public func load() async {
        linked = await auth.linkedProviders()
    }

    public func isLinked(_ provider: AuthProvider) -> Bool {
        linked.contains(provider)
    }

    /// The account keeps at least one way to sign in.
    public func canUnlink(_ provider: AuthProvider) -> Bool {
        isLinked(provider) && linked.count > 1
    }

    public func link(_ provider: AuthProvider) async {
        guard busy == nil, !isLinked(provider) else { return }
        busy = provider
        defer { busy = nil }
        errorKey = nil
        do {
            let method = try await credential(provider)
            _ = try await auth.link(method)
            linked = await auth.linkedProviders()
            lastChange = (provider, true)
        } catch {
            errorKey = Self.messageKey(for: error)
        }
    }

    public func unlink(_ provider: AuthProvider) async {
        guard busy == nil else { return }
        guard canUnlink(provider) else {
            errorKey = KitStrings.LinkedAccounts.lastProvider
            return
        }
        busy = provider
        defer { busy = nil }
        errorKey = nil
        do {
            _ = try await auth.unlink(provider)
            linked = await auth.linkedProviders()
            lastChange = (provider, false)
        } catch {
            errorKey = Self.messageKey(for: error)
        }
    }

    public func dismissMessages() {
        errorKey = nil
        lastChange = nil
    }

    static func messageKey(for error: TitanError) -> String? {
        switch error {
        case .cancelled: nil
        case AuthFailure.credentialInUse: KitStrings.LinkedAccounts.inUse
        case AuthFailure.lastProvider: KitStrings.LinkedAccounts.lastProvider
        case AuthFailure.alreadyLinked: nil
        // Firebase wants a recent sign-in before changing how the account signs in.
        case .unauthorized: KitStrings.LinkedAccounts.signInAgain
        default: error.messageKey
        }
    }
}
