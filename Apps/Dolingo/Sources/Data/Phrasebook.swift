import Foundation
import TitanCore
import TitanStorage

/// A Speak tab topic: phrases to practise saying aloud.
/// Loaded from `Resources/Phrasebook/phrasebook-<language>.json`.
struct PhraseCategory: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let emoji: String
    let title: [String: String]
    let isPremium: Bool
    let phrases: [Phrase]
}

protocol PhrasebookRepository: Sendable {
    func categories(language: String) async throws(TitanError) -> [PhraseCategory]
}

/// The phrasebook shipped inside the app as a JSON file.
struct BundledPhrasebookRepository: PhrasebookRepository {
    var bundle: Bundle = .main

    private struct File: Decodable {
        let categories: [PhraseCategory]
    }

    func categories(language: String) async throws(TitanError) -> [PhraseCategory] {
        guard let url = bundle.url(forResource: "phrasebook-\(language)", withExtension: "json") else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(File.self, from: data).categories
        } catch {
            throw .decoding(error.localizedDescription)
        }
    }
}

/// Phrases the learner bookmarked while practising, newest first.
@MainActor
final class SavedPhrases: ObservableObject {
    @Published private(set) var phrases: [Phrase]

    private let preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
        phrases = preferences.value(DolingoKeys.savedPhrases)
    }

    func contains(_ phrase: Phrase) -> Bool {
        phrases.contains(phrase)
    }

    /// Saves the phrase, or removes it when it is already saved.
    func toggle(_ phrase: Phrase) {
        if let index = phrases.firstIndex(of: phrase) {
            phrases.remove(at: index)
        } else {
            phrases.insert(phrase, at: 0)
        }
        preferences.set(phrases, for: DolingoKeys.savedPhrases)
    }
}
