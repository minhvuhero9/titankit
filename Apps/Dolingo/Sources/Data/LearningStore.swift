import Foundation
import TitanCore
import TitanStorage

/// What the learner has done, saved in Preferences.
struct LearningProgress: Codable, Equatable, Sendable {
    /// Ids of the finished lessons of the English course.
    var completedLessons: Set<String> = []
}

enum LessonStatus: Equatable, Sendable {
    case done, current, locked
}

/// Loads the English course and keeps the learner's progress in it.
@MainActor
final class LearningStore: ObservableObject {
    @Published private(set) var progress: LearningProgress
    /// The course: `.loaded(nil)` only if the bundled course file is missing.
    @Published private(set) var course: LoadState<Course?> = .idle

    private let repository: any CourseRepository
    private let preferences: Preferences

    init(repository: any CourseRepository, preferences: Preferences) {
        self.repository = repository
        self.preferences = preferences
        progress = preferences.value(DolingoKeys.learningProgress)
    }

    func load() async {
        course = .loading
        do {
            course = .loaded(try await repository.course(language: AppConfig.learningLanguage))
        } catch {
            course = .failed(error)
        }
    }

    func complete(_ lesson: Lesson) {
        update { $0.completedLessons.insert(lesson.id) }
    }

    private var completed: Set<String> {
        progress.completedLessons
    }

    /// Lessons open one after another: the first unfinished one is current, the rest are locked.
    func status(of lesson: Lesson, in course: Course) -> LessonStatus {
        Self.status(of: lesson.id, lessons: course.lessons.map(\.id), completed: completed)
    }

    /// The lesson the learner should do next, nil once the course is finished.
    func currentLesson(in course: Course) -> Lesson? {
        course.lessons.first { !completed.contains($0.id) }
    }

    /// Chapters with every lesson finished.
    var chaptersDone: Int {
        guard case let .loaded(course?) = course else { return 0 }
        return course.chapters.filter { progress(of: $0) >= 1 }.count
    }

    /// Share of the chapter's lessons finished, from 0 to 1.
    func progress(of chapter: Chapter) -> Double {
        guard !chapter.lessons.isEmpty else { return 0 }
        let done = chapter.lessons.filter { completed.contains($0.id) }.count
        return Double(done) / Double(chapter.lessons.count)
    }

    /// A chapter opens once the learner reaches its first lesson.
    func isUnlocked(_ chapter: Chapter, in course: Course) -> Bool {
        guard let first = chapter.lessons.first else { return false }
        return status(of: first, in: course) != .locked
    }

    nonisolated static func status(of lessonId: String, lessons: [String], completed: Set<String>) -> LessonStatus {
        if completed.contains(lessonId) { return .done }
        return lessons.first { !completed.contains($0) } == lessonId ? .current : .locked
    }

    private func update(_ change: (inout LearningProgress) -> Void) {
        change(&progress)
        preferences.set(progress, for: DolingoKeys.learningProgress)
    }
}
