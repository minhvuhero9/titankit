import Foundation
import TitanCore
import TitanSpeech

/// Speaking practice on one topic: the learner says each phrase, sees a score, and moves back
/// and forth between phrases freely.
@MainActor
final class PhrasePracticeViewModel: ObservableObject {
    enum Attempt: Equatable {
        case idle
        case listening
        case scored(PronunciationScore)
    }

    @Published private(set) var index = 0
    @Published private(set) var attempt: Attempt = .idle
    /// No microphone or speech permission: the learner can still listen and save phrases.
    @Published private(set) var isMicBlocked = false

    let category: PhraseCategory
    let language: String
    private let speech: any SpeechRecognizer
    private var hasPermission = false

    init(category: PhraseCategory, language: String, speech: any SpeechRecognizer) {
        self.category = category
        self.language = language
        self.speech = speech
    }

    var phrase: Phrase? {
        category.phrases.indices.contains(index) ? category.phrases[index] : nil
    }

    var progress: Double {
        guard !category.phrases.isEmpty else { return 0 }
        return Double(index + 1) / Double(category.phrases.count)
    }

    var score: PronunciationScore? {
        if case let .scored(score) = attempt { return score }
        return nil
    }

    var canGoBack: Bool { index > 0 }
    var canGoForward: Bool { index + 1 < category.phrases.count }

    func speak() async {
        guard let phrase, attempt != .listening, !isMicBlocked else { return }
        if !hasPermission {
            hasPermission = await speech.requestAuthorization()
            guard hasPermission else {
                isMicBlocked = true
                return
            }
        }
        attempt = .listening
        do {
            let heard = try await speech.transcribe(language: language, timeout: .seconds(8))
            attempt = .scored(PronunciationScore(expected: phrase.text, heard: heard))
        } catch {
            if error == .unauthorized { isMicBlocked = true }
            attempt = .idle
        }
    }

    func stopListening() {
        speech.stop()
    }

    func next() {
        guard canGoForward, attempt != .listening else { return }
        index += 1
        attempt = .idle
    }

    func previous() {
        guard canGoBack, attempt != .listening else { return }
        index -= 1
        attempt = .idle
    }
}
