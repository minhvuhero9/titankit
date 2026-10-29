import Foundation
import TitanCore
import TitanSpeech

/// Steps through a lesson's phrases: the user says each one, gets a score, and moves on once
/// it passes (or skips it). Times the lesson and averages the scores for the "completed" screen.
@MainActor
final class LessonViewModel: ObservableObject {
    enum Attempt: Equatable {
        case idle
        case listening
        case scored(PronunciationScore)
    }

    @Published private(set) var index = 0
    @Published private(set) var attempt: Attempt = .idle
    @Published private(set) var isFinished = false
    /// No microphone or speech permission: the lesson becomes listen and read only.
    @Published private(set) var isMicBlocked = false
    /// Set when the lesson ends, for the "Time" card.
    @Published private(set) var duration: TimeInterval = 0

    let lesson: Lesson
    let language: String
    private let speech: any SpeechRecognizer
    private let startedAt: Date
    private let now: () -> Date
    private var hasPermission = false
    /// Best score for each phrase index; a skipped phrase counts as 0.
    private var bestScores: [Int: Double] = [:]

    init(lesson: Lesson, language: String, speech: any SpeechRecognizer, now: @escaping () -> Date = Date.init) {
        self.lesson = lesson
        self.language = language
        self.speech = speech
        self.now = now
        startedAt = now()
    }

    var phrase: Phrase? {
        lesson.phrases.indices.contains(index) ? lesson.phrases[index] : nil
    }

    /// From 0 before the first phrase to 1 when the lesson ends.
    var progress: Double {
        guard !lesson.phrases.isEmpty else { return 1 }
        return Double(isFinished ? lesson.phrases.count : index) / Double(lesson.phrases.count)
    }

    var score: PronunciationScore? {
        if case let .scored(score) = attempt { return score }
        return nil
    }

    /// Continue shows once the phrase passed, or always when speaking is not possible.
    var canContinue: Bool {
        isMicBlocked || (score?.verdict.isPass ?? false)
    }

    /// Average of the phrase scores, nil when nothing was scored (no microphone).
    var accuracy: Double? {
        guard !bestScores.isEmpty else { return nil }
        return bestScores.values.reduce(0, +) / Double(bestScores.count)
    }

    /// The microphone button: listens, then scores what was heard.
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
            let score = PronunciationScore(expected: phrase.text, heard: heard)
            bestScores[index] = max(bestScores[index] ?? 0, score.value)
            attempt = .scored(score)
        } catch {
            if error == .unauthorized { isMicBlocked = true }
            attempt = .idle
        }
    }

    /// Stops listening early; the score comes from what was heard so far.
    func stopListening() {
        speech.stop()
    }

    /// Next phrase, or the end of the lesson after the last one.
    func next() {
        guard !isFinished else { return }
        if !isMicBlocked, bestScores[index] == nil {
            bestScores[index] = 0
        }
        attempt = .idle
        if index + 1 < lesson.phrases.count {
            index += 1
        } else {
            isFinished = true
            duration = now().timeIntervalSince(startedAt)
        }
    }

    /// "2:25" for the Time card.
    nonisolated static func formatted(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
