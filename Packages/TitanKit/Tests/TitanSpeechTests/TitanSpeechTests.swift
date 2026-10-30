import XCTest
import TitanCore
@testable import TitanSpeech

final class PronunciationScoreTests: XCTestCase {
    func testSamePhraseIsPerfectWhateverThePunctuationAndCase() {
        let score = PronunciationScore(expected: "¡Encantado de conocerte!", heard: "encantado de conocerte")
        XCTAssertEqual(score.percent, 100)
        XCTAssertEqual(score.verdict, .perfect)
        XCTAssertTrue(score.words.allSatisfy(\.isMatched))
        XCTAssertEqual(score.words.map(\.text), ["¡Encantado", "de", "conocerte!"])
    }

    func testAccentsDoNotCount() {
        XCTAssertEqual(PronunciationScore(expected: "¿Cómo estás?", heard: "como estas").verdict, .perfect)
    }

    func testMissingWordIsAlmostThere() {
        let score = PronunciationScore(expected: "Encantado de conocerte", heard: "encantado de conocer")
        XCTAssertEqual(score.percent, 67)
        XCTAssertEqual(score.verdict, .almostThere)
        XCTAssertEqual(score.words.map(\.isMatched), [true, true, false])
    }

    func testExtraWordsDoNotShiftTheMatch() {
        let score = PronunciationScore(expected: "I am fine thank you", heard: "um I am very fine thank you")
        XCTAssertEqual(score.verdict, .perfect)
    }

    func testWrongWordsTryAgain() {
        let score = PronunciationScore(expected: "Good morning everyone", heard: "good night")
        XCTAssertEqual(score.verdict, .tryAgain)
        XCTAssertFalse(score.verdict.isPass)
    }

    func testSilenceIsNotHeard() {
        let score = PronunciationScore(expected: "Hello", heard: "  ")
        XCTAssertEqual(score.verdict, .notHeard)
        XCTAssertEqual(score.percent, 0)
    }

    func testWordsMatchInOrder() {
        XCTAssertEqual(PronunciationScore.matches(["a", "b", "c"], ["c", "a", "b"]), [true, true, false])
        XCTAssertEqual(PronunciationScore.matches([], ["a"]), [])
        XCTAssertEqual(PronunciationScore.matches(["a"], []), [false])
    }
}

final class MockSpeechRecognizerTests: XCTestCase {
    func testReturnsTranscriptsInTurnAndRepeatsTheLast() async throws {
        let speech = MockSpeechRecognizer(transcripts: ["hola", "adiós"])
        let first = try await speech.transcribe(language: "es", timeout: .seconds(5))
        let second = try await speech.transcribe(language: "es", timeout: .seconds(5))
        let third = try await speech.transcribe(language: "es", timeout: .seconds(5))
        XCTAssertEqual([first, second, third], ["hola", "adiós", "adiós"])
        XCTAssertEqual(speech.requestedLanguages, ["es", "es", "es"])
    }

    func testWithoutPermissionThrowsUnauthorized() async {
        let speech = MockSpeechRecognizer(isAuthorized: false)
        let granted = await speech.requestAuthorization()
        XCTAssertFalse(granted)
        do {
            _ = try await speech.transcribe(language: "en", timeout: .seconds(5))
            XCTFail("Expected unauthorized")
        } catch {
            XCTAssertEqual(error, .unauthorized)
        }
    }
}
