import SwiftUI
import XCTest
import TitanAuth
import TitanCore
import TitanLocalization
@testable import TitanFeatures

@MainActor
final class SurveyViewModelTests: XCTestCase {
    private func steps() -> [SurveyStep] {
        [
            SurveyStep("language", title: Text(verbatim: "Language?"), kind: .single([
                SurveyOption("en", title: Text(verbatim: "English")),
                SurveyOption("es", title: Text(verbatim: "Spanish")),
            ])),
            SurveyStep("topics", title: Text(verbatim: "Topics?"), kind: .chips([
                SurveyOption("travel", title: Text(verbatim: "Travel")),
                SurveyOption("music", title: Text(verbatim: "Music")),
            ])),
            SurveyStep("reminder", title: Text(verbatim: "When?"), kind: .time(hour: 20, minute: 0)),
        ]
    }

    func testOneAnswerStepKeepsTheLastPick() {
        let viewModel = SurveyViewModel(steps: steps())
        XCTAssertFalse(viewModel.canContinue)
        viewModel.select("en")
        viewModel.select("es")
        XCTAssertEqual(viewModel.answers["language"], .options(["es"]))
        XCTAssertTrue(viewModel.canContinue)
    }

    func testUnknownOptionIsIgnored() {
        let viewModel = SurveyViewModel(steps: steps())
        viewModel.select("music")
        XCTAssertNil(viewModel.answers["language"])
    }

    func testChipsToggle() {
        let viewModel = SurveyViewModel(steps: steps())
        viewModel.select("en")
        XCTAssertFalse(viewModel.next())
        viewModel.select("travel")
        viewModel.select("music")
        viewModel.select("travel")
        XCTAssertEqual(viewModel.answers["topics"], .options(["music"]))
        XCTAssertTrue(viewModel.isSelected("music"))
    }

    func testTimeStepSavesItsStartingTimeAndFinishes() {
        let viewModel = SurveyViewModel(steps: steps())
        viewModel.select("en")
        _ = viewModel.next()
        viewModel.select("travel")
        _ = viewModel.next()
        XCTAssertTrue(viewModel.canContinue)
        XCTAssertEqual(viewModel.time.hour, 20)
        XCTAssertEqual(viewModel.progress, 1)
        XCTAssertTrue(viewModel.next())
        XCTAssertEqual(viewModel.answers["reminder"], .time(hour: 20, minute: 0))
    }

    func testChangedTimeIsKept() {
        let viewModel = SurveyViewModel(steps: steps(), answers: ["language": .options(["en"]), "topics": .options(["music"])])
        _ = viewModel.next()
        _ = viewModel.next()
        viewModel.setTime(hour: 7, minute: 30)
        XCTAssertTrue(viewModel.next())
        XCTAssertEqual(viewModel.answers["reminder"], .time(hour: 7, minute: 30))
    }

    func testBackLeavesFromTheFirstStep() {
        let viewModel = SurveyViewModel(steps: steps())
        XCTAssertFalse(viewModel.back())
        viewModel.select("en")
        _ = viewModel.next()
        XCTAssertEqual(viewModel.index, 1)
        XCTAssertTrue(viewModel.back())
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertTrue(viewModel.isSelected("en"))
    }

    func testAnswersRoundTripThroughJSON() throws {
        let answers: [String: SurveyAnswer] = ["a": .options(["x", "y"]), "b": .time(hour: 9, minute: 5)]
        let data = try JSONEncoder().encode(answers)
        XCTAssertEqual(try JSONDecoder().decode([String: SurveyAnswer].self, from: data), answers)
    }

    func testPreparingRingOnlyShowsFullAtTheEnd() {
        XCTAssertEqual(PreparingScreen.progress(tick: 1, of: 50), 0.02, accuracy: 0.0001)
        XCTAssertEqual(PreparingScreen.progress(tick: 50, of: 50), 1)
        XCTAssertLessThan(PreparingScreen.progress(tick: 49, of: 50), 1)
    }
}

@MainActor
final class SignUpViewModelTests: XCTestCase {
    func testWalksThroughTheStepsAndCreatesTheAccount() async {
        let auth = MockAuthService()
        let viewModel = SignUpViewModel(auth: auth)
        XCTAssertFalse(viewModel.canContinue)
        viewModel.name = "  An "
        let afterName = await viewModel.next()
        XCTAssertNil(afterName)
        XCTAssertEqual(viewModel.step, .email)

        viewModel.email = "an@titan.app"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .password)

        viewModel.password = "123456"
        viewModel.confirmPassword = "123456"
        let user = await viewModel.next()
        XCTAssertEqual(user?.email, "an@titan.app")
        XCTAssertEqual(user?.displayName, "An")
        XCTAssertFalse(viewModel.isCreating)
    }

    func testInvalidEmailStaysOnTheStep() async {
        let viewModel = SignUpViewModel(auth: MockAuthService(), name: "An")
        _ = await viewModel.next()
        viewModel.email = "an@titan"
        _ = await viewModel.next()
        XCTAssertEqual(viewModel.step, .email)
        XCTAssertEqual(viewModel.emailErrorKey, KitStrings.Login.invalidEmail)
    }

    func testPasswordsMustMatchAndBeLongEnough() async {
        let viewModel = SignUpViewModel(auth: MockAuthService(), name: "An")
        _ = await viewModel.next()
        viewModel.email = "an@titan.app"
        _ = await viewModel.next()
        viewModel.password = "123"
        viewModel.confirmPassword = "124"
        let user = await viewModel.next()
        XCTAssertNil(user)
        XCTAssertEqual(viewModel.passwordErrorKey, KitStrings.Login.shortPassword)
        XCTAssertEqual(viewModel.confirmErrorKey, KitStrings.SignUp.passwordMismatch)
    }

    func testTakenEmailShowsAnError() async {
        let auth = MockAuthService()
        _ = try? await auth.signUp(email: "an@titan.app", password: "123456", displayName: nil)
        let viewModel = SignUpViewModel(auth: auth, name: "An")
        _ = await viewModel.next()
        viewModel.email = "an@titan.app"
        _ = await viewModel.next()
        viewModel.password = "123456"
        viewModel.confirmPassword = "123456"
        let user = await viewModel.next()
        XCTAssertNil(user)
        XCTAssertNotNil(viewModel.errorKey)
    }

    func testBackGoesToThePreviousStepThenLeaves() async {
        let viewModel = SignUpViewModel(auth: MockAuthService(), name: "An")
        _ = await viewModel.next()
        XCTAssertTrue(viewModel.back())
        XCTAssertEqual(viewModel.step, .name)
        XCTAssertFalse(viewModel.back())
    }

    func testEverySignUpStringExistsInBothLanguages() {
        let keys = [
            KitStrings.continueAction, KitStrings.SignUp.nameTitle, KitStrings.SignUp.nameLabel,
            KitStrings.SignUp.emailTitle, KitStrings.SignUp.passwordTitle, KitStrings.SignUp.confirmPassword,
            KitStrings.SignUp.passwordMismatch, KitStrings.SignUp.submit, KitStrings.SignUp.creating,
        ]
        for key in keys {
            for code in ["vi", "en"] {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}
