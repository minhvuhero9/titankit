import Foundation

/// Steps through a lesson's phrases and times the lesson for the "completed" screen.
@MainActor
final class LessonViewModel: ObservableObject {
    @Published private(set) var index = 0
    @Published private(set) var isFinished = false
    /// Set when the lesson ends, for the "Time" card.
    @Published private(set) var duration: TimeInterval = 0

    let lesson: Lesson
    private let startedAt: Date
    private let now: () -> Date

    init(lesson: Lesson, now: @escaping () -> Date = Date.init) {
        self.lesson = lesson
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

    /// Next phrase, or the end of the lesson after the last one.
    func next() {
        guard !isFinished else { return }
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
