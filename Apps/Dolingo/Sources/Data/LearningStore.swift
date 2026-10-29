import Foundation
import TitanCore
import TitanStorage

/// What the learner has done, saved in Preferences: the courses they added, the one they
/// are on, and the lessons they finished in each.
struct LearningProgress: Codable, Equatable, Sendable {
    /// Language codes, in the order the courses were added.
    var courses: [String] = []
    var activeCourse: String?
    /// Finished lesson ids by course language.
    var completedLessons: [String: Set<String>] = [:]
}

enum LessonStatus: Equatable, Sendable {
    case done, current, locked
}

/// Loads the active course and keeps the learner's progress in it.
@MainActor
final class LearningStore: ObservableObject {
    @Published private(set) var progress: LearningProgress
    /// The active course: `.loaded(nil)` when Dolingo has no course for that language yet.
    @Published private(set) var course: LoadState<Course?> = .idle

    private let repository: any CourseRepository
    private let preferences: Preferences

    init(repository: any CourseRepository, preferences: Preferences) {
        self.repository = repository
        self.preferences = preferences
        progress = preferences.value(DolingoKeys.learningProgress)
    }

    /// The language being learned; English until the learner picks one.
    var activeLanguage: String {
        progress.activeCourse ?? progress.courses.first ?? "en"
    }

    /// Adds the language picked in the sign-up questionnaire as the first course.
    func startIfNeeded(language: String?) {
        guard progress.courses.isEmpty else { return }
        let language = language ?? "en"
        update {
            $0.courses = [language]
            $0.activeCourse = language
        }
    }

    func load() async {
        course = .loading
        do {
            course = .loaded(try await repository.course(language: activeLanguage))
        } catch {
            course = .failed(error)
        }
    }

    /// Switches to a course, adding it to My Courses the first time.
    func select(language: String) async {
        update {
            if !$0.courses.contains(language) { $0.courses.append(language) }
            $0.activeCourse = language
        }
        await load()
    }

    func complete(_ lesson: Lesson) {
        update { $0.completedLessons[activeLanguage, default: []].insert(lesson.id) }
    }

    private var completed: Set<String> {
        progress.completedLessons[activeLanguage] ?? []
    }

    /// Lessons open one after another: the first unfinished one is current, the rest are locked.
    func status(of lesson: Lesson, in course: Course) -> LessonStatus {
        Self.status(of: lesson.id, lessons: course.lessons.map(\.id), completed: completed)
    }

    /// The lesson the learner should do next, nil once the course is finished.
    func currentLesson(in course: Course) -> Lesson? {
        course.lessons.first { !completed.contains($0.id) }
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
