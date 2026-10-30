import Foundation
import TitanAI
import TitanCore

/// Figma "create roleplay": the learner writes what they like, the sparkle buttons let the AI fill
/// one field, and "Start Chatting" has the AI complete the rest and write the goals.
@MainActor
final class CreateRoleplayViewModel: ObservableObject {
    enum Field: Sendable {
        case myRole, aiRole, scenario
    }

    @Published var title: String
    @Published var myRole: String
    @Published var aiRole: String
    @Published var scenario: String
    @Published var withGoals: Bool
    @Published private(set) var emoji: String?
    /// The field a sparkle button is filling.
    @Published private(set) var fillingField: Field?
    /// "Generating scenario...".
    @Published private(set) var isGenerating = false
    /// Localizable key of the last error, shown as a toast.
    @Published private(set) var errorKey: String?

    /// The roleplay being edited; nil when creating a new one.
    let editing: CustomRoleplay?
    private let ai: any RoleplayAI
    private let learner: @MainActor () async -> ChatLearner

    init(editing: CustomRoleplay? = nil, ai: any RoleplayAI,
         learner: @escaping @MainActor () async -> ChatLearner = { ChatLearner() }) {
        self.editing = editing
        self.ai = ai
        self.learner = learner
        title = editing?.title ?? ""
        myRole = editing?.myRole ?? ""
        aiRole = editing?.aiRole ?? ""
        scenario = editing?.scenario ?? ""
        withGoals = editing.map { !$0.tasks.isEmpty } ?? true
        emoji = editing?.emoji
    }

    var isBusy: Bool {
        isGenerating || fillingField != nil
    }

    /// The sparkle button: the AI writes this field to fit the others.
    func fill(_ field: Field) async {
        guard !isBusy else { return }
        fillingField = field
        defer { fillingField = nil }
        var form = await makeForm(withGoals: false)
        switch field {
        case .myRole: form.myRole = ""
        case .aiRole: form.aiRole = ""
        case .scenario: form.scenario = ""
        }
        guard let draft = await draft(form) else { return }
        switch field {
        case .myRole: myRole = draft.myRole
        case .aiRole: aiRole = draft.aiRole
        case .scenario: scenario = draft.scenario
        }
        if title.isBlank { title = draft.title }
        if emoji == nil { emoji = draft.emoji }
    }

    /// "Start Chatting": the finished roleplay, or nil when the AI could not answer (see `errorKey`).
    func create() async -> CustomRoleplay? {
        guard !isBusy else { return nil }
        isGenerating = true
        defer { isGenerating = false }
        guard let draft = await draft(await makeForm(withGoals: withGoals)) else { return nil }
        var roleplay = editing ?? CustomRoleplay(emoji: draft.emoji, title: "", myRole: "", aiRole: "", scenario: "", tasks: [])
        roleplay.emoji = emoji ?? draft.emoji
        roleplay.title = draft.title
        roleplay.myRole = draft.myRole
        roleplay.aiRole = draft.aiRole
        roleplay.scenario = draft.scenario
        roleplay.tasks = withGoals ? draft.tasks.enumerated().map { index, goal in
            RoleplayTask(id: "goal\(index + 1)", text: goal.text, meaning: ["vi": goal.meaning, "en": goal.text])
        } : []
        return roleplay
    }

    func dismissError() {
        errorKey = nil
    }

    private func makeForm(withGoals: Bool) async -> RoleplayForm {
        RoleplayForm(title: trimmed(title), myRole: trimmed(myRole), aiRole: trimmed(aiRole),
                     scenario: trimmed(scenario), withGoals: withGoals, learner: await learner())
    }

    private func draft(_ form: RoleplayForm) async -> RoleplayDraft? {
        errorKey = nil
        do {
            switch try await ai.draft(form) {
            case let .answer(draft):
                return draft
            case .refused:
                errorKey = "createRoleplay.error.refused"
            }
        } catch {
            if error != .cancelled {
                errorKey = error == .network(.server(statusCode: 429)) ? "ai.error.limit"
                    : error == .network(.offline) ? "tutor.error.offline.short" : "createRoleplay.error.failed"
            }
        }
        return nil
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
