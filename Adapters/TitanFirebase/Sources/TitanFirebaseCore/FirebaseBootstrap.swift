import FirebaseCore
import Foundation

/// Starts Firebase from the app's own `GoogleService-Info` file, one per environment, so a build
/// without the file (CI, a new clone) runs on the kit's mocks instead of crashing.
///
///     if FirebaseBootstrap.configure(plistName: "GoogleService-Info-Dev") { auth = FirebaseAuthService() }
public enum FirebaseBootstrap {
    /// - Returns: true when Firebase is running, false when the file is missing or unreadable.
    @discardableResult
    public static func configure(plistName: String, bundle: Bundle = .main) -> Bool {
        if FirebaseApp.app() != nil { return true }
        guard let path = bundle.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else { return false }
        FirebaseApp.configure(options: options)
        return true
    }

    public static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }

    /// The OAuth client id from the plist, which Google Sign-In needs.
    public static var clientID: String? {
        FirebaseApp.app()?.options.clientID
    }
}
