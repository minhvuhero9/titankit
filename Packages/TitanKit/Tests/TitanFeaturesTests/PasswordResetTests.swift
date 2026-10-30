import XCTest
import TitanAuth
import TitanCore
import TitanLocalization
@testable import TitanFeatures

@MainActor
final class PasswordResetViewModelTests: XCTestCase {
    private final class Clock {
        var now = Date(timeIntervalSince1970: 0)
    }

    private let time = Clock()
    private var clock: Date {
        get { time.now }
        set { time.now = newValue }
    }

    private func makeViewModel(_ auth: MockAuthService = MockAuthService()) -> PasswordResetViewModel {
        let time = time
        return PasswordResetViewModel(auth: auth, email: "demo@titan.app", resendDelay: 60) { time.now }
    }

    func testResetsThePasswordAndSignsIn() async {
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth)
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .code)
        let requests = await auth.resetRequests
        XCTAssertEqual(requests, ["demo@titan.app"])

        XCTAssertFalse(viewModel.canContinue)
        viewModel.code = "1234"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .password)

        viewModel.password = "brandnew"
        viewModel.confirmPassword = "brandnew"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .done)

        let user = await viewModel.next()
        XCTAssertEqual(user?.email, "demo@titan.app")
    }

    func testInvalidEmailStaysOnTheStep() async {
        let viewModel = makeViewModel()
        viewModel.email = "demo@titan"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .email)
        XCTAssertEqual(viewModel.emailErrorKey, KitStrings.Login.invalidEmail)
    }

    func testWrongCodeIsClearedAndMarked() async {
        let viewModel = makeViewModel()
        _ = await viewModel.next()
        viewModel.code = "0000"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .code)
        XCTAssertTrue(viewModel.isCodeWrong)
        XCTAssertEqual(viewModel.code, "")
        XCTAssertEqual(viewModel.errorKey, KitStrings.PasswordReset.wrongCode)
        viewModel.code = "1"
        XCTAssertFalse(viewModel.isCodeWrong)
    }

    func testResendWaitsForTheCountdown() async {
        let auth = MockAuthService()
        let viewModel = makeViewModel(auth)
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.secondsUntilResend(at: clock), 60)
        await viewModel.resend()
        var requests = await auth.resetRequests
        XCTAssertEqual(requests.count, 1)

        clock = clock.addingTimeInterval(59.5)
        XCTAssertEqual(viewModel.secondsUntilResend(at: clock), 1)
        clock = clock.addingTimeInterval(1)
        XCTAssertEqual(viewModel.secondsUntilResend(at: clock), 0)
        await viewModel.resend()
        requests = await auth.resetRequests
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(viewModel.noticeKey, KitStrings.PasswordReset.codeSent)
        XCTAssertEqual(viewModel.secondsUntilResend(at: clock), 60)
    }

    func testPasswordsMustMatch() async {
        let viewModel = makeViewModel()
        _ = await viewModel.next()
        viewModel.code = "1234"
        _ = await viewModel.next()
        viewModel.password = "brandnew"
        viewModel.confirmPassword = "brandnex"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .password)
        XCTAssertEqual(viewModel.confirmErrorKey, KitStrings.SignUp.passwordMismatch)
    }

    func testBackGoesThroughTheStepsThenLeaves() async {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.back())
        _ = await viewModel.next()
        viewModel.code = "1234"
        _ = await viewModel.next()
        XCTAssertTrue(viewModel.back())
        XCTAssertEqual(viewModel.step, .code)
        XCTAssertEqual(viewModel.code, "")
        XCTAssertTrue(viewModel.back())
        XCTAssertEqual(viewModel.step, .email)
    }

    func testOfflineShowsTheErrorAndStays() async {
        let auth = MockAuthService()
        await auth.fail(next: .network(.offline))
        let viewModel = makeViewModel(auth)
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .email)
        XCTAssertEqual(viewModel.errorKey, TitanError.network(.offline).messageKey)
    }

    func testLinkBackendsStopAtCheckYourEmail() async {
        let auth = MockAuthService()
        let time = time
        let viewModel = PasswordResetViewModel(auth: auth, email: "demo@titan.app", resendDelay: 60, sendsLink: true) {
            time.now
        }
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .linkSent)
        clock = clock.addingTimeInterval(61)
        await viewModel.resend()
        let requests = await auth.resetRequests
        XCTAssertEqual(requests.count, 2)
        XCTAssertTrue(viewModel.back())
        XCTAssertEqual(viewModel.step, .email)
    }
}

@MainActor
final class LinkedAccountsViewModelTests: XCTestCase {
    private func signedIn() async throws -> MockAuthService {
        let auth = MockAuthService()
        _ = try await auth.signIn(.email(email: "demo@titan.app", password: "123456"))
        return auth
    }

    func testLinksWithTheProvidersCredential() async throws {
        let auth = try await signedIn()
        var asked: [AuthProvider] = []
        let viewModel = LinkedAccountsViewModel(auth: auth) { provider in
            asked.append(provider)
            return .google(idToken: "id", accessToken: "token")
        }
        await viewModel.load()
        XCTAssertEqual(viewModel.linked, [.email])
        XCTAssertFalse(viewModel.canUnlink(.email))
        await viewModel.link(.google)
        XCTAssertEqual(asked, [.google])
        XCTAssertEqual(viewModel.linked, [.email, .google])
        XCTAssertEqual(viewModel.lastChange?.provider, .google)
        XCTAssertTrue(viewModel.canUnlink(.google))
        await viewModel.unlink(.google)
        XCTAssertEqual(viewModel.linked, [.email])
        XCTAssertEqual(viewModel.lastChange?.isLinked, false)
    }

    func testExplainsWhyLinkingFailed() async throws {
        let auth = try await signedIn()
        await auth.markTaken(.apple)
        let viewModel = LinkedAccountsViewModel(auth: auth) { _ in .apple(idToken: "id", rawNonce: "n", fullName: nil) }
        await viewModel.load()
        await viewModel.link(.apple)
        XCTAssertEqual(viewModel.errorKey, KitStrings.LinkedAccounts.inUse)
        await viewModel.unlink(.email)
        XCTAssertEqual(viewModel.errorKey, KitStrings.LinkedAccounts.lastProvider)
    }

    func testClosingTheSheetIsQuiet() async throws {
        let auth = try await signedIn()
        let viewModel = LinkedAccountsViewModel(auth: auth) { (_: AuthProvider) async throws(TitanError) -> SignInMethod in
            throw .cancelled
        }
        await viewModel.link(.google)
        XCTAssertNil(viewModel.errorKey)
        XCTAssertNil(viewModel.busy)
    }
}
