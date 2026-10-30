import FirebaseCore
import GoogleSignIn
import TitanAuth
import TitanCore
import UIKit

/// Shows Google's sign-in page and returns the tokens Firebase needs. The client id comes from
/// the app's GoogleService-Info file; the app also registers its REVERSED_CLIENT_ID as a URL
/// scheme and passes opened URLs to `handle(_:)`.
///
///     let method = try await GoogleSignInHelper.request()
///     let user = try await auth.signIn(method)
@MainActor
public enum GoogleSignInHelper {
    /// Throws `.cancelled` when the user closes the page.
    public static func request() async throws(TitanError) -> SignInMethod {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw .unknown("Google Sign-In needs CLIENT_ID in GoogleService-Info")
        }
        guard let presenter = topViewController() else { throw .unknown("no window to show Google Sign-In") }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                throw TitanError.unknown("Google returned no identity token")
            }
            return .google(idToken: idToken, accessToken: result.user.accessToken.tokenString)
        } catch let error as TitanError {
            throw error
        } catch {
            if (error as? GIDSignInError)?.code == .canceled { throw .cancelled }
            throw .unknown(error.localizedDescription)
        }
    }

    /// The URL Google opens after signing in; true when it was Google's.
    @discardableResult
    public static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    public static func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }

    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
