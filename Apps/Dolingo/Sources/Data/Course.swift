import Foundation
import TitanCore

/// One language course: chapters of lessons, each lesson a few phrases said by a tutor.
/// Loaded from `Resources/Courses/<language>.json` until the backend serves courses.
struct Course: Codable, Equatable, Sendable, Identifiable {
    /// The language taught, e.g. "en", "es"; also the id.
    let language: String
    let chapters: [Chapter]

    var id: String { language }

    /// Every lesson in order, across chapters.
    var lessons: [Lesson] { chapters.flatMap(\.lessons) }
}

struct Chapter: Codable, Equatable, Sendable, Identifiable {
    let id: String
    /// Title in each app language, e.g. ["vi": "Làm quen", "en": "Getting started"].
    let title: [String: String]
    let lessons: [Lesson]
}

struct Lesson: Codable, Equatable, Sendable, Identifiable {
    let id: String
    /// The tutor's first name; their initials stand in for the photo.
    let tutor: String
    let title: [String: String]
    let phrases: [Phrase]
}

struct Phrase: Codable, Equatable, Sendable {
    /// In the language being learned.
    let text: String
    /// What it means, in each app language.
    let meaning: [String: String]
}

extension Dictionary where Key == String, Value == String {
    /// The value for `language`, else English, else any value.
    func localized(_ language: String) -> String {
        self[language] ?? self["en"] ?? values.first ?? ""
    }
}

protocol CourseRepository: Sendable {
    /// nil when Dolingo has no course for that language yet.
    func course(language: String) async throws(TitanError) -> Course?
}

/// Courses shipped inside the app as JSON files.
struct BundledCourseRepository: CourseRepository {
    var bundle: Bundle = .main

    /// Languages with a course file.
    static let available = ["en", "es"]

    func course(language: String) async throws(TitanError) -> Course? {
        guard let url = bundle.url(forResource: language, withExtension: "json", subdirectory: "Courses")
            ?? bundle.url(forResource: language, withExtension: "json") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Course.self, from: data)
        } catch {
            throw .decoding(error.localizedDescription)
        }
    }
}
