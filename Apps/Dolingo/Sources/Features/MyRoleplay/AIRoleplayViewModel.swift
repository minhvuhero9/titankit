import Foundation
import TitanAI
import TitanCore
import TitanSpeech

/// Figma "roleplay chat" for the learner's own roleplays: the AI plays its role, opens the
/// scene, answers whatever the learner says, ticks off goals and suggests a reply.
@MainActor
final class AIRoleplayViewModel: ObservableObject {
    enum State: Equatable {
        /// The AI is writing its line.
        case thinking
        case ready
        case listening
        /// The microphone heard nothing.
        case notHeard
        /// The AI's opening line could not be fetched; "Try again" asks again.
        case failed
        case finished
    }

    @Published private(set) var messages: [RoleplayViewModel.Message] = []
    @Published private(set) var state: State = .thinking
    @Published private(set) var completedTasks: Set<String> = []
    @Published private(set) var hint: RoleplayReply?
    /// No microphone or speech permission: the learner sends the hint instead of speaking.
    @Published private(set) var isMicBlocked = false
    /// Localizable key of the last error, shown as a toast.
    @Published private(set) var errorKey: String?

    let roleplay: CustomRoleplay
    let language: String
    private let ai: any RoleplayAI
    private let speech: any SpeechRecognizer
    private let activity: ActivityStore?
    private let learner: @MainActor () async -> ChatLearner
    private let startedAt = Date()
    private var hasPermission = false

    init(
        roleplay: CustomRoleplay,
        language: String,
        ai: any RoleplayAI,
        speech: any SpeechRecognizer,
        activity: ActivityStore? = nil,
        learner: @escaping @MainActor () async -> ChatLearner = { ChatLearner() }
    ) {
        self.roleplay = roleplay
        self.language = language
        self.ai = ai
        self.speech = speech
        self.activity = activity
        self.learner = learner
    }

    var taskCount: Int { roleplay.tasks.count }

    var completedTaskCount: Int {
        roleplay.tasks.filter { completedTasks.contains($0.id) }.count
    }

    func isDone(_ task: RoleplayTask) -> Bool {
        completedTasks.contains(task.id)
    }

    /// The AI's opening line; also "Try again" after it failed.
    func start() async {
        guard messages.isEmpty, state == .thinking || state == .failed else { return }
        state = .thinking
        let answered = await askForNextLine()
        if !answered { state = .failed }
    }

    /// The microphone button: listens, then sends what was heard.
    func speak() async {
        guard state == .ready || state == .notHeard, !isMicBlocked else { return }
        if !hasPermission {
            hasPermission = await speech.requestAuthorization()
            guard hasPermission else {
                isMicBlocked = true
                return
            }
        }
        state = .listening
        do {
            let heard = try await speech.transcribe(language: language, timeout: .seconds(10))
            if heard.isBlank {
                state = .notHeard
            } else {
                await say(heard)
            }
        } catch {
            if error == .unauthorized { isMicBlocked = true }
            state = .ready
        }
    }

    func stopListening() {
        speech.stop()
    }

    /// Sends the learner's line and waits for the AI's answer. Used for what the microphone
    /// heard, and for the hint when the microphone is off.
    func say(_ text: String) async {
        guard state == .ready || state == .notHeard || state == .listening else { return }
        let line = RoleplayViewModel.Message(id: messages.count, phrase: Phrase(text: text, meaning: [:]), isMine: true)
        messages.append(line)
        hint = nil
        state = .thinking
        let answered = await askForNextLine()
        if !answered {
            // Nothing came back: the line goes away so the learner can say it again.
            messages.removeAll { $0.id == line.id }
            state = .ready
        }
    }

    func dismissError() {
        errorKey = nil
    }

    private func askForNextLine() async -> Bool {
        errorKey = nil
        let turns = messages.map { RoleplayTurnRequest.Line(role: $0.isMine ? "user" : "assistant", text: $0.phrase.text) }
        let request = RoleplayTurnRequest(roleplay: roleplay, turns: turns, learner: await learner())
        do {
            switch try await ai.turn(request) {
            case let .answer(turn):
                apply(turn)
                return true
            case .refused:
                errorKey = "createRoleplay.error.refused"
            }
        } catch {
            if error != .cancelled {
                errorKey = error == .network(.offline) ? "tutor.error.offline.short" : "createRoleplay.error.failed"
            }
        }
        return false
    }

    private func apply(_ turn: RoleplayTurn) {
        let known = Set(roleplay.tasks.map(\.id))
        completedTasks.formUnion(turn.completedTaskIds.filter(known.contains))
        messages.append(RoleplayViewModel.Message(
            id: messages.count,
            phrase: Phrase(text: turn.reply, meaning: ["vi": turn.translation, "en": turn.reply]),
            isMine: false
        ))
        if turn.isFinished {
            hint = nil
            state = .finished
            activity?.recordRoleplay(tasksDone: completedTaskCount, tasksTotal: taskCount,
                                     seconds: Date().timeIntervalSince(startedAt))
        } else {
            hint = RoleplayReply(text: turn.hint, meaning: ["vi": turn.hintTranslation, "en": turn.hint], completes: [])
            state = .ready
        }
    }
}
