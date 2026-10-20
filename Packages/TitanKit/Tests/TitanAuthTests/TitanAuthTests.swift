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
}
