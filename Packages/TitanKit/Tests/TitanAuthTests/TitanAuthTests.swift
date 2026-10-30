import XCTest
import TitanCore
@testable import TitanAuth

final class CredentialsTests: XCTestCase {
    func testEmailCheck() {
        for valid in ["a@b.co", "john.doe@domain.com", " jack@titan.app "] {
            XCTAssertTrue(Credentials.isValidEmail(valid), valid)
        }
        for invalid in ["", "john", "john@", "@domain.com", "john@domain", "john@.com", "a@b@c.com", "john@dom ain.com"] {
            XCTAssertFalse(Credentials.isValidEmail(invalid), invalid)
        }
    }

    func testPasswordLength() {
        XCTAssertFalse(Credentials.isValidPassword("12345"))
        XCTAssertTrue(Credentials.isValidPassword("123456"))
    }
}

final class MockAuthServiceTests: XCTestCase {
    func testEmailSignInChecksPassword() async throws {
        let auth = MockAuthService(accounts: ["Jack@Titan.app": "secret1"])
        do {
            _ = try await auth.signIn(.email(email: "jack@titan.app", password: "wrong"))
            XCTFail("expected unauthorized")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
        let user = try await auth.signIn(.email(email: "jack@titan.app", password: "secret1"))
        XCTAssertEqual(user.email, "jack@titan.app")
        let current = await auth.currentUser()
        XCTAssertEqual(current, user)
    }

    func testNextErrorIsThrownOnce() async throws {
        let auth = MockAuthService()
        await auth.fail(next: .network(.offline))
        do {
            try await auth.signOut()
            XCTFail("expected offline")
        } catch {
            XCTAssertEqual(error, .network(.offline))
        }
        try await auth.signOut()
    }

    func testSignUpThenDelete() async throws {
        let auth = MockAuthService(accounts: [:])
        _ = try await auth.signUp(email: "new@titan.app", password: "123456", displayName: "New")
        try await auth.deleteAccount()
        let current = await auth.currentUser()
        XCTAssertNil(current)
        do {
            _ = try await auth.signIn(.email(email: "new@titan.app", password: "123456"))
            XCTFail("deleted account should not sign in")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testUpdateProfileKeepsTheAccount() async throws {
        let auth = MockAuthService()
        do {
            _ = try await auth.updateProfile(displayName: "Nobody")
            XCTFail("needs a signed-in user")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
        _ = try await auth.signIn(.email(email: "demo@titan.app", password: "123456"))
        let updated = try await auth.updateProfile(displayName: "Jack")
        XCTAssertEqual(updated.displayName, "Jack")
        try await auth.signOut()
        let again = try await auth.signIn(.email(email: "demo@titan.app", password: "123456"))
        XCTAssertEqual(again.displayName, "Jack")
        try await auth.deleteAccount()
        let current = await auth.currentUser()
        XCTAssertNil(current)
    }

    func testPasswordResetWithTheEmailedCode() async throws {
        let auth = MockAuthService(resetCode: "4321")
        try await auth.sendPasswordReset(email: "Demo@titan.app")
        do {
            _ = try await auth.verifyPasswordResetCode(email: "demo@titan.app", code: "0000")
            XCTFail("wrong code")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
        let token = try await auth.verifyPasswordResetCode(email: "demo@titan.app", code: "4321")
        try await auth.resetPassword(token: token, newPassword: "newpass")
        let user = try await auth.signIn(.email(email: "demo@titan.app", password: "newpass"))
        XCTAssertEqual(user.email, "demo@titan.app")
        do {
            try await auth.resetPassword(token: token, newPassword: "again1")
            XCTFail("a token works once")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testResetCodeNeedsARequestFirst() async {
        let auth = MockAuthService()
        do {
            _ = try await auth.verifyPasswordResetCode(email: "demo@titan.app", code: "1234")
            XCTFail("no email was sent")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testMockTokenNeedsASignedInUser() async throws {
        let auth = MockAuthService()
        do {
            _ = try await auth.idToken(forceRefresh: false)
            XCTFail("signed out")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
        let user = try await auth.signIn(.anonymous)
        let token = try await auth.idToken(forceRefresh: true)
        XCTAssertEqual(token, "mock-token-\(user.id)")
    }

    func testAppleNonceIsRandomAndHashed() {
        let first = AppleSignInHelper.randomNonce()
        XCTAssertEqual(first.count, 32)
        XCTAssertNotEqual(first, AppleSignInHelper.randomNonce())
        XCTAssertEqual(AppleSignInHelper.sha256("abc"),
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
