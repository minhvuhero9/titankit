import XCTest
import TitanAuth
import TitanCore
import TitanLocalization
@testable import TitanFeatures

@MainActor
final class LoginViewModelTests: XCTestCase {
    private func makeViewModel(_ auth: MockAuthService = MockAuthService()) -> LoginViewModel {
        LoginViewModel(auth: auth)
    }

    func testCannotSubmitEmptyForm() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.email = "demo@titan.app"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.password = "1"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testFieldErrorsAppearOnlyAfterSubmit() async {
        let viewModel = makeViewModel()
        viewModel.email = "not-an-email"
        viewModel.password = "123"
        XCTAssertNil(viewModel.emailErrorKey)
        let user = await viewModel.signIn()
        XCTAssertNil(user)
        XCTAssertEqual(viewModel.emailErrorKey, KitStrings.Login.invalidEmail)
        XCTAssertEqual(viewModel.passwordErrorKey, KitStrings.Login.shortPassword)
        XCTAssertNil(viewModel.errorKey)
    }

    func testSuccessReturnsUser() async {
        let viewModel = makeViewModel()
        viewModel.email = " demo@titan.app "
        viewModel.password = "123456"
        let user = await viewModel.signIn()
        XCTAssertEqual(user?.email, "demo@titan.app")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorKey)
    }

    func testWrongPasswordShowsCredentialsMessage() async {
        let viewModel = makeViewModel()
        viewModel.email = "demo@titan.app"
        viewModel.password = "wrong-password"
        _ = await viewModel.signIn()
        XCTAssertEqual(viewModel.errorKey, KitStrings.Login.invalidCredentials)
    }

    func testOfflineShowsOfflineMessage() async {
        let auth = MockAuthService()
        await auth.fail(next: .network(.offline))
        let viewModel = makeViewModel(auth)
        viewModel.email = "demo@titan.app"
        viewModel.password = "123456"
        _ = await viewModel.signIn()
        XCTAssertEqual(viewModel.errorKey, TitanError.network(.offline).messageKey)
    }

    func testCancelShowsNothing() {
        XCTAssertNil(LoginViewModel.messageKey(for: .cancelled))
    }

    func testEveryLoginStringExistsInBothLanguages() {
        let keys = [
            KitStrings.Login.title, KitStrings.Login.subtitle, KitStrings.Login.email, KitStrings.Login.password,
            KitStrings.Login.forgotPassword, KitStrings.Login.orContinueWith, KitStrings.Login.submit,
            KitStrings.Login.noAccount, KitStrings.Login.signUp, KitStrings.Login.invalidCredentials,
            KitStrings.Login.invalidEmail, KitStrings.Login.shortPassword,
            KitStrings.Onboarding.getStarted, KitStrings.Onboarding.haveAccount, KitStrings.loading, KitStrings.back,
        ]
        for key in keys {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}

@MainActor
final class SplashTimerTests: XCTestCase {
    func testWaitsAtLeastTheMinimum() async {
        let clock = ContinuousClock()
        let start = clock.now
        await SplashTimer.run(minimum: .milliseconds(200)) {}
        XCTAssertGreaterThanOrEqual(clock.now - start, .milliseconds(200))
    }

    func testDoesNotAddDelayAfterSlowWork() async {
        let clock = ContinuousClock()
        let start = clock.now
        var ran = false
        await SplashTimer.run(minimum: .milliseconds(50)) {
            try? await Task.sleep(for: .milliseconds(200))
            ran = true
        }
        XCTAssertTrue(ran)
        XCTAssertLessThan(clock.now - start, .milliseconds(1000))
    }
}
