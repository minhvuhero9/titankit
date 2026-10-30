import AuthenticationServices
import CryptoKit
import Foundation
import TitanCore
import UIKit

/// Shows the system "Sign in with Apple" sheet and returns what any backend needs to sign in:
/// Apple's identity token, the raw nonce whose hash Apple signed, and the name (first time only).
/// The app target needs the "Sign in with Apple" capability.
///
///     let method = try await AppleSignInHelper().request()
///     let user = try await auth.signIn(method)
@MainActor
public final class AppleSignInHelper: NSObject {
    /// What the sheet returns: the sign-in, plus the one-time authorization code a backend needs
    /// to revoke the user's Apple tokens when the account is deleted (App Store guideline 5.1.1(v)).
    public struct Authorization: Sendable {
        public let method: SignInMethod
        public let authorizationCode: String?
    }

    private var continuation: CheckedContinuation<Authorization, any Error>?
    private var rawNonce = ""

    override public init() {
        super.init()
    }

    /// Throws `.cancelled` when the user closes the sheet.
    public func request() async throws(TitanError) -> SignInMethod {
        try await authorize().method
    }

    /// The sheet again, for deleting the account: a fresh sign-in and the authorization code.
    /// Throws `.cancelled` when the user closes the sheet.
    public func authorize() async throws(TitanError) -> Authorization {
        let nonce = Self.randomNonce()
        rawNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        do {
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                controller.performRequests()
            }
        } catch let error as TitanError {
            throw error
        } catch {
            throw .unknown(error.localizedDescription)
        }
    }

    private func finish(_ result: Result<Authorization, TitanError>) {
        continuation?.resume(with: result.mapError { $0 as any Error })
        continuation = nil
    }

    /// 32 random characters from a URL-safe set.
    nonisolated static func randomNonce(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in characters[Int(generator.next(upperBound: UInt(characters.count)))] })
    }

    nonisolated static func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInHelper: @preconcurrency ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            finish(.failure(.unknown("Apple returned no identity token")))
            return
        }
        let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        finish(.success(Authorization(method: .apple(idToken: token, rawNonce: rawNonce, fullName: credential.fullName),
                                      authorizationCode: code)))
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        let code = (error as? ASAuthorizationError)?.code
        finish(.failure(code == .canceled ? .cancelled : .unknown(error.localizedDescription)))
    }
}

extension AppleSignInHelper: @preconcurrency ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
