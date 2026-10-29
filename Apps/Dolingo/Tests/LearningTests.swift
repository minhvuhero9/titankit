import XCTest
import TitanCore
import TitanSpeech
import TitanStorage
@testable import Dolingo

@MainActor
final class LearningStoreTests: XCTestCase {
    private func makePreferences() -> Preferences {
        let defaults = UserDefaults(suiteName: "LearningStoreTests")!
        defaults.removePersistentDomain(forName: "LearningStoreTests")
        return Preferences(defaults: defaults)
    }

    func testBundledCoursesDecode() async throws {
        let repository = BundledCourseRepository()
        for language in BundledCourseRepository.available {
            let course = try await repository.course(language: language)
            XCTAssertEqual(course?.language, language)
            XCTAssertEqual(course?.chapters.count, 3)
            XCTAssertEqual(course?.lessons.count, 15)
            XCTAssertEqual(Set(course?.lessons.map(\.id) ?? []).count, 15, "lesson ids are unique")
            XCTAssertTrue(course?.lessons.allSatisfy { !$0.phrases.isEmpty } ?? false)
        }
        let missing = try await repository.course(language: "ko")
        XCTAssertNil(missing)
    }

    func testStartsWithTheSurveyLanguageOnce() {
        let store = LearningStore(repository: BundledCourseRepository(), preferences: makePreferences())
        store.startIfNeeded(language: "es")
        store.startIfNeeded(language: "en")
        XCTAssertEqual(store.progress.courses, ["es"])
        XCTAssertEqual(store.activeLanguage, "es")
    }

    func testLessonsOpenOneAfterAnother() async throws {
        let preferences = makePreferences()
        let store = LearningStore(repository: BundledCourseRepository(), preferences: preferences)
        store.startIfNeeded(language: "en")
        await store.load()
        let course = try XCTUnwrap(store.course.value.flatMap { $0 })
        let first = course.lessons[0], second = course.lessons[1], third = course.lessons[2]
        XCTAssertEqual(store.status(of: first, in: course), .current)
        XCTAssertEqual(store.status(of: second, in: course), .locked)

        store.complete(first)
        XCTAssertEqual(store.status(of: first, in: course), .done)
        XCTAssertEqual(store.status(of: second, in: course), .current)
        XCTAssertEqual(store.status(of: third, in: course), .locked)
        XCTAssertEqual(store.currentLesson(in: course)?.id, second.id)
        XCTAssertEqual(store.progress(of: course.chapters[0]), 0.2, accuracy: 0.001)
        XCTAssertTrue(store.isUnlocked(course.chapters[0], in: course))
        XCTAssertFalse(store.isUnlocked(course.chapters[1], in: course))

        let reopened = LearningStore(repository: BundledCourseRepository(), preferences: preferences)
        XCTAssertEqual(reopened.progress.completedLessons["en"], [first.id])
    }

    func testSwitchingCourseAddsItAndKeepsProgressApart() async {
        let store = LearningStore(repository: BundledCourseRepository(), preferences: makePreferences())
        store.startIfNeeded(language: "en")
        await store.select(language: "ko")
        XCTAssertEqual(store.progress.courses, ["en", "ko"])
        XCTAssertEqual(store.course, .loaded(nil))
        await store.select(language: "en")
        XCTAssertEqual(store.progress.courses, ["en", "ko"])
        XCTAssertEqual(store.activeLanguage, "en")
    }

    func testPathSwingsWithinTheWidth() {
        let centers = LessonPath.centers(count: 9, width: 390)
        XCTAssertEqual(centers.count, 9)
        XCTAssertEqual(centers[0].x, 195)
        XCTAssertTrue(centers.allSatisfy { $0.x >= LessonPath.nodeSize / 2 && $0.x <= 390 - LessonPath.nodeSize / 2 })
        XCTAssertEqual(centers[1].y - centers[0].y, LessonPath.rowHeight)
    }
}

@MainActor
final class LessonViewModelTests: XCTestCase {
    private let lesson = Lesson(id: "l1", tutor: "Emma", title: ["en": "Greetings"], phrases: [
        Phrase(text: "Hello!", meaning: ["vi": "Xin chào!"]),
        Phrase(text: "Good morning.", meaning: ["vi": "Chào buổi sáng."]),
    ])

    func testPassingPhrasesTimesTheLessonAndAveragesTheScores() async {
        var clock = Date(timeIntervalSince1970: 0)
        let speech = MockSpeechRecognizer(transcripts: ["hello", "good evening"])
        let viewModel = LessonViewModel(lesson: lesson, language: "en", speech: speech) { clock }
        XCTAssertEqual(viewModel.phrase?.text, "Hello!")
        XCTAssertFalse(viewModel.canContinue)

        await viewModel.speak()
        XCTAssertEqual(viewModel.score?.verdict, .perfect)
        XCTAssertTrue(viewModel.canContinue)
        viewModel.next()
        XCTAssertEqual(viewModel.progress, 0.5)
        XCTAssertEqual(viewModel.attempt, .idle)

        await viewModel.speak()
        XCTAssertEqual(viewModel.score?.verdict, .tryAgain)
        XCTAssertFalse(viewModel.canContinue)
        clock = Date(timeIntervalSince1970: 145)
        viewModel.next()
        XCTAssertTrue(viewModel.isFinished)
        XCTAssertEqual(viewModel.progress, 1)
        XCTAssertEqual(LessonViewModel.formatted(viewModel.duration), "2:25")
        XCTAssertEqual(viewModel.accuracy ?? -1, 0.75, accuracy: 0.001)
        XCTAssertEqual(speech.requestedLanguages, ["en", "en"])
    }

    func testRetryKeepsTheBestScore() async {
        let speech = MockSpeechRecognizer(transcripts: ["", "hello"])
        let viewModel = LessonViewModel(lesson: lesson, language: "en", speech: speech)
        await viewModel.speak()
        XCTAssertEqual(viewModel.score?.verdict, .notHeard)
        await viewModel.speak()
        XCTAssertEqual(viewModel.score?.verdict, .perfect)
        viewModel.next()
        viewModel.next()
        XCTAssertEqual(viewModel.accuracy ?? -1, 0.5, accuracy: 0.001)
    }

    func testWithoutMicrophoneTheLessonIsReadOnly() async {
        let viewModel = LessonViewModel(lesson: lesson, language: "en", speech: MockSpeechRecognizer(isAuthorized: false))
        await viewModel.speak()
        XCTAssertTrue(viewModel.isMicBlocked)
        XCTAssertTrue(viewModel.canContinue)
        viewModel.next()
        viewModel.next()
        XCTAssertTrue(viewModel.isFinished)
        XCTAssertNil(viewModel.accuracy)
    }

    func testMeaningFallsBackToEnglish() {
        XCTAssertEqual(["en": "Hi", "vi": "Chào"].localized("vi"), "Chào")
        XCTAssertEqual(["en": "Hi"].localized("vi"), "Hi")
    }
}
