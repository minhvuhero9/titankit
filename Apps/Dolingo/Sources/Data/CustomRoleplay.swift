import Foundation
import TitanAI
import TitanCore
import TitanStorage

/// A roleplay the learner set up with "Create Roleplay"; the AI plays the other role.
struct CustomRoleplay: Codable, Hashable, Sendable, Identifiable {
    var id = UUID().uuidString
    var emoji: String
    var title: String
    var myRole: String
    var aiRole: String
    var scenario: String
    /// Goals the AI wrote, with their Vietnamese meaning; empty when goals were turned off.
    var tasks: [RoleplayTask]
    var createdAt = Date()
}

/// "My Roleplay": the learner's own roleplays, newest first, and how many free creations are used.
@MainActor
final class MyRoleplays: ObservableObject {
    /// Creations a free learner gets before Premium (Figma "You have 10 trials").
    static let freeCreations = 10

    @Published private(set) var roleplays: [CustomRoleplay]
    @Published private(set) var creationsUsed: Int

    private let preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
        roleplays = preferences.value(DolingoKeys.myRoleplays)
        creationsUsed = preferences.value(DolingoKeys.roleplayCreations)
    }

    var trialsLeft: Int {
        max(0, Self.freeCreations - creationsUsed)
    }

    func roleplay(id: String) -> CustomRoleplay? {
        roleplays.first { $0.id == id }
    }

    /// Adds a new roleplay on top, or replaces the one with the same id after an edit.
    /// A new one uses up a free creation.
    func save(_ roleplay: CustomRoleplay) {
        if let index = roleplays.firstIndex(where: { $0.id == roleplay.id }) {
            roleplays[index] = roleplay
        } else {
            roleplays.insert(roleplay, at: 0)
            creationsUsed += 1
            preferences.set(creationsUsed, for: DolingoKeys.roleplayCreations)
        }
        preferences.set(roleplays, for: DolingoKeys.myRoleplays)
    }

    func delete(id: String) {
        roleplays.removeAll { $0.id == id }
        preferences.set(roleplays, for: DolingoKeys.myRoleplays)
    }
}

// MARK: - The AI server's roleplay calls

/// The Create Roleplay form; empty fields are for the AI to fill.
struct RoleplayForm: Codable, Sendable, Equatable {
    var title = ""
    var myRole = ""
    var aiRole = ""
    var scenario = ""
    var withGoals = true
    var learner = ChatLearner()
}

/// The form filled in by the AI.
struct RoleplayDraft: Codable, Sendable, Equatable {
    struct Goal: Codable, Sendable, Equatable {
        let text: String
        /// In Vietnamese.
        let meaning: String
    }

    let emoji: String
    let title: String
    let myRole: String
    let aiRole: String
    let scenario: String
    let tasks: [Goal]
}

/// The roleplay and the conversation so far, for the AI's next line.
struct RoleplayTurnRequest: Encodable, Sendable, Equatable {
    struct Setup: Encodable, Sendable, Equatable {
        struct Task: Encodable, Sendable, Equatable {
            let id: String
            let text: String
        }

        let title: String
        let myRole: String
        let aiRole: String
        let scenario: String
        let tasks: [Task]
    }

    struct Line: Encodable, Sendable, Equatable {
        /// "assistant" for the AI partner, "user" for the learner.
        let role: String
        let text: String
    }

    let roleplay: Setup
    let turns: [Line]
    let learner: ChatLearner

    init(roleplay: CustomRoleplay, turns: [Line], learner: ChatLearner) {
        self.roleplay = Setup(
            title: roleplay.title, myRole: roleplay.myRole, aiRole: roleplay.aiRole, scenario: roleplay.scenario,
            tasks: roleplay.tasks.map { Setup.Task(id: $0.id, text: $0.text) }
        )
        self.turns = turns
        self.learner = learner
    }
}

/// The AI partner's next line.
struct RoleplayTurn: Codable, Sendable, Equatable {
    let reply: String
    /// The reply in Vietnamese.
    let translation: String
    /// Tasks the learner's last message completed.
    let completedTaskIds: [String]
    /// Something the learner could say next, and its Vietnamese.
    let hint: String
    let hintTranslation: String
    let isFinished: Bool
}

protocol RoleplayAI: Sendable {
    func draft(_ form: RoleplayForm) async throws(TitanError) -> AIAnswer<RoleplayDraft>
    func turn(_ request: RoleplayTurnRequest) async throws(TitanError) -> AIAnswer<RoleplayTurn>
}

/// `POST /v1/roleplay/draft` and `/v1/roleplay/turn` on the Dolingo AI server.
struct RemoteRoleplayAI: RoleplayAI {
    let client: AIServerClient

    func draft(_ form: RoleplayForm) async throws(TitanError) -> AIAnswer<RoleplayDraft> {
        try await client.post("v1/roleplay/draft", body: form, as: RoleplayDraft.self)
    }

    func turn(_ request: RoleplayTurnRequest) async throws(TitanError) -> AIAnswer<RoleplayTurn> {
        try await client.post("v1/roleplay/turn", body: request, as: RoleplayTurn.self)
    }
}

/// Answers without a server: a pizza order, for previews, tests and builds without the AI server.
struct MockRoleplayAI: RoleplayAI {
    var delay: Duration = .zero

    func draft(_ form: RoleplayForm) async throws(TitanError) -> AIAnswer<RoleplayDraft> {
        await wait()
        func or(_ value: String, _ fallback: String) -> String { value.isBlank ? fallback : value }
        let goals = form.withGoals ? [
            RoleplayDraft.Goal(text: "Greet the waiter", meaning: "Chào người phục vụ"),
            RoleplayDraft.Goal(text: "Order a pizza", meaning: "Gọi một chiếc pizza"),
            RoleplayDraft.Goal(text: "Ask the price", meaning: "Hỏi giá"),
        ] : []
        return .answer(RoleplayDraft(
            emoji: "🍕",
            title: or(form.title, "Ordering Pizza"),
            myRole: or(form.myRole, "Customer"),
            aiRole: or(form.aiRole, "Pizza Shop Employee"),
            scenario: or(form.scenario, "You're at a pizza shop and want to order a pizza."),
            tasks: goals
        ))
    }

    func turn(_ request: RoleplayTurnRequest) async throws(TitanError) -> AIAnswer<RoleplayTurn> {
        await wait()
        let learnerTurns = request.turns.filter { $0.role == "user" }.count
        let tasks = request.roleplay.tasks
        let completed = learnerTurns > 0 && learnerTurns <= tasks.count ? [tasks[learnerTurns - 1].id] : []
        let isLast = learnerTurns >= max(tasks.count, 1)
        return .answer(RoleplayTurn(
            reply: isLast ? "Thank you, have a great day!" : learnerTurns == 0 ? "Hi! What can I get you?" : "Sure. Anything else?",
            translation: isLast ? "Cảm ơn bạn, chúc một ngày tốt lành!" : learnerTurns == 0 ? "Chào bạn! Bạn muốn dùng gì?" : "Được ạ. Bạn cần gì nữa không?",
            completedTaskIds: completed,
            hint: "I'd like a pizza, please.",
            hintTranslation: "Cho tôi một chiếc pizza.",
            isFinished: isLast
        ))
    }

    private func wait() async {
        if delay > .zero { try? await Task.sleep(for: delay) }
    }
}
