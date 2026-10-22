import TitanCore

/// Everything the app and the kit's screens need from a login backend.
/// Every call throws only TitanError: `.unauthorized` for wrong credentials,
/// `.network(.offline)`, `.cancelled` when the user backs out of Apple or Google sign-in.
public protocol AuthService: Sendable {
    func currentUser() async -> AuthUser?
    func signIn(_ method: SignInMethod) async throws(TitanError) -> AuthUser
    func signUp(email: String, password: String, displayName: String?) async throws(TitanError) -> AuthUser
    func sendPasswordReset(email: String) async throws(TitanError)
    /// Changes the signed-in user's name and returns the updated user.
    func updateProfile(displayName: String) async throws(TitanError) -> AuthUser
    func signOut() async throws(TitanError)
    /// Throws `.unauthorized` when the backend wants a fresh sign-in first.
    func deleteAccount() async throws(TitanError)
}
