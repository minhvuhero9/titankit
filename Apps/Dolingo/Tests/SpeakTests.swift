import XCTest
import TitanCore
import TitanSpeech
import TitanStorage
@testable import Dolingo

@MainActor
final class SpeakTests: XCTestCase {
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "SpeakTests")!
        defaults.removePersistentDomain(forName: "SpeakTests")
        return Preferences(defaults: defaults)
    }

    private func greetings() async throws -> PhraseCategory {
        let categories = try await BundledPhrasebookRepository().categories(language: AppConfig.learningLanguage)
        return try XCTUnwrap(categories.first)
    }

    func testBundledPhrasebookIsWellFormed() async throws {
        let categories = try await BundledPhrasebookRepository().categories(language: AppConfig.learningLanguage)
        XCTAssertEqual(categories.count, 7)
        XCTAssertEqual(categories.filter(\.isPremium).count, 3)
        XCTAssertEqual(Set(categories.map(\.id)).count, 7)
        for category in categories {
            XCTAssertEqual(category.phrases.count, 8, category.id)
            XCTAssertTrue(category.phrases.allSatisfy { $0.meaning["vi"] != nil }, category.id)
        }
    }

    func testPracticeScoresAndMovesBetweenPhrases() async throws {
        let category = try await greetings()
        let speech = MockSpeechRecognizer(transcripts: ["hello how are you", "I'm good"])
        let viewModel = PhrasePracticeViewModel(category: category, language: "en", speech: speech)
        XCTAssertFalse(viewModel.canGoBack)
        XCTAssertEqual(viewModel.progress, 1.0 / 8, accuracy: 0.001)

        await viewModel.speak()
        XCTAssertEqual(viewModel.score?.verdict, .perfect)

        viewModel.next()
        XCTAssertEqual(viewModel.index, 1)
        XCTAssertEqual(viewModel.attempt, .idle)
        await viewModel.speak()
        XCTAssertEqual(viewModel.score?.verdict, .tryAgain)

        viewModel.previous()
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertNil(viewModel.score)
    }

    func testCannotGoPastTheLastPhrase() async throws {
        let category = try await greetings()
        let viewModel = PhrasePracticeViewModel(category: category, language: "en", speech: MockSpeechRecognizer())
        for _ in 0..<20 { viewModel.next() }
        XCTAssertEqual(viewModel.index, category.phrases.count - 1)
        XCTAssertFalse(viewModel.canGoForward)
        XCTAssertEqual(viewModel.progress, 1)
    }

    func testWithoutMicrophoneSpeakingIsBlocked() async throws {
        let category = try await greetings()
        let viewModel = PhrasePracticeViewModel(category: category, language: "en", speech: MockSpeechRecognizer(isAuthorized: false))
        await viewModel.speak()
        XCTAssertTrue(viewModel.isMicBlocked)
        XCTAssertNil(viewModel.score)
    }

    func testSavedPhrasesToggleAndPersist() {
        let preferences = makePreferences()
        let saved = SavedPhrases(preferences: preferences)
        let hello = Phrase(text: "Hello", meaning: ["vi": "Xin chào"])
        let bye = Phrase(text: "Bye", meaning: ["vi": "Tạm biệt"])
        saved.toggle(hello)
        saved.toggle(bye)
        XCTAssertEqual(saved.phrases, [bye, hello])
        saved.toggle(hello)
        XCTAssertFalse(saved.contains(hello))
        XCTAssertEqual(SavedPhrases(preferences: preferences).phrases, [bye])
    }
}
