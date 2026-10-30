import Foundation
import TitanCore

/// A scripted conversation: the partner says a line, the learner answers with one of the
/// expected replies, and each reply can complete some of the tasks. The last turn is the
/// partner's goodbye and has no replies.
/// Loaded from `Resources/Roleplays/roleplays-<language>.json`.
struct Roleplay: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let emoji: String
    let title: [String: String]
    let scenario: [String: String]
    /// The partner's first name, shown on their avatar.
    let partner: String
    let isPremium: Bool
    /// The first task is the goal; the others are "Also try".
    let tasks: [RoleplayTask]
    let turns: [RoleplayTurn]
}

struct RoleplayTask: Codable, Hashable, Sendable, Identifiable {
    let id: String
    /// In the language being learned, with its meaning.
    let text: String
    let meaning: [String: String]
}

struct RoleplayTurn: Codable, Hashable, Sendable {
    let partner: Phrase
    let replies: [RoleplayReply]
}

struct RoleplayReply: Codable, Hashable, Sendable {
    let text: String
    let meaning: [String: String]
    /// Ids of the tasks this reply completes.
    let completes: [String]

    var phrase: Phrase { Phrase(text: text, meaning: meaning) }
}

protocol RoleplayRepository: Sendable {
    /// Roleplays for the language being learned; empty when there are none yet.
    func roleplays(language: String) async throws(TitanError) -> [Roleplay]
}

/// Roleplays shipped inside the app as JSON files.
struct BundledRoleplayRepository: RoleplayRepository {
    var bundle: Bundle = .main

    private struct File: Decodable {
        let roleplays: [Roleplay]
    }

    func roleplays(language: String) async throws(TitanError) -> [Roleplay] {
        guard let url = bundle.url(forResource: "roleplays-\(language)", withExtension: "json") else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(File.self, from: data).roleplays
        } catch {
            throw .decoding(error.localizedDescription)
        }
    }
}
