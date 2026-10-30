import TitanCore

/// Everything the app and the kit's screens need from a login backend.
/// Every call throws only TitanError: `.unauthorized` for wrong credentials,
/// `.network(.offline)`, `.cancelled` when the user backs out of Apple or Google sign-in.
public protocol AuthService: Sendable {
    func currentUser() async -> AuthUser?
    func signIn(_ method: SignInMethod) async throws(TitanError) -> AuthUser
    func signUp(email: String, password: String, displayName: String?) async throws(TitanError) -> AuthUser
    /// Emails a one-time code for resetting the password. Succeeds even when no account uses
    /// the address, so the form can't be used to find out who has an account.
    func sendPasswordReset(email: String) async throws(TitanError)
    /// Checks the emailed code. Returns a token for `resetPassword`; throws `.unauthorized`
    /// when the code is wrong or has expired.
    func verifyPasswordResetCode(email: String, code: String) async throws(TitanError) -> String
    /// Sets a new password with the token from `verifyPasswordResetCode`.
    func resetPassword(token: String, newPassword: String) async throws(TitanError)
    /// Changes the signed-in user's name and returns the updated user.
    func updateProfile(displayName: String) async throws(TitanError) -> AuthUser
    func signOut() async throws(TitanError)
    /// Throws `.unauthorized` when the backend wants a fresh sign-in first.
    func deleteAccount() async throws(TitanError)
}
