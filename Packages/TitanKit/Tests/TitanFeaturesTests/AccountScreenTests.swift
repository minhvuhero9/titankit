import XCTest
import TitanAuth
import TitanCore
import TitanLocalization
@testable import TitanFeatures

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private func signedIn() -> MockAuthService {
        MockAuthService(signedIn: AuthUser(id: "1", email: "an@titan.app", displayName: "An", provider: .email))
    }

    func testLoadsTheSignedInUser() async {
        let viewModel = ProfileViewModel(auth: signedIn())
        await viewModel.load()
        XCTAssertEqual(viewModel.name, "An")
        XCTAssertEqual(viewModel.user?.email, "an@titan.app")
        XCTAssertFalse(viewModel.canSave)
    }

    func testSavesOnlyAChangedNonBlankName() async {
        let viewModel = ProfileViewModel(auth: signedIn())
        await viewModel.load()
        viewModel.name = "   "
        XCTAssertFalse(viewModel.canSave)
        viewModel.name = " An Nguyen "
        XCTAssertTrue(viewModel.canSave)
        let saved = await viewModel.save()
        XCTAssertEqual(saved?.displayName, "An Nguyen")
        XCTAssertEqual(viewModel.name, "An Nguyen")
        XCTAssertFalse(viewModel.canSave)
    }

    func testOfflineSaveShowsOfflineMessage() async {
        let auth = signedIn()
        let viewModel = ProfileViewModel(auth: auth)
        await viewModel.load()
        viewModel.name = "Binh"
        await auth.fail(next: .network(.offline))
        let saved = await viewModel.save()
        XCTAssertNil(saved)
        XCTAssertEqual(viewModel.errorKey, TitanError.network(.offline).messageKey)
    }
}

@MainActor
final class DeleteAccountViewModelTests: XCTestCase {
    func testNeedsTheConfirmationTick() async {
        let auth = MockAuthService(signedIn: AuthUser(id: "1", email: nil, provider: .apple))
        let viewModel = DeleteAccountViewModel(auth: auth)
        let refused = await viewModel.delete()
        XCTAssertFalse(refused)
        viewModel.hasConfirmed = true
        let deleted = await viewModel.delete()
        XCTAssertTrue(deleted)
        let current = await auth.currentUser()
        XCTAssertNil(current)
    }

    func testStaleSessionAsksToSignInAgain() {
        XCTAssertEqual(DeleteAccountViewModel.messageKey(for: .unauthorized), KitStrings.DeleteAccount.signInAgain)
        XCTAssertNil(DeleteAccountViewModel.messageKey(for: .cancelled))
    }

    func testEveryAccountStringExistsInBothLanguages() {
        let keys = [
            KitStrings.Profile.title, KitStrings.Profile.name, KitStrings.Profile.email,
            KitStrings.Profile.save, KitStrings.Profile.saved,
            KitStrings.DeleteAccount.title, KitStrings.DeleteAccount.warning,
            KitStrings.DeleteAccount.lossProgress, KitStrings.DeleteAccount.lossProfile,
            KitStrings.DeleteAccount.lossSubscription, KitStrings.DeleteAccount.confirmCheck,
            KitStrings.DeleteAccount.confirmTitle, KitStrings.DeleteAccount.action,
            KitStrings.DeleteAccount.signInAgain,
        ]
        for key in keys {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}
