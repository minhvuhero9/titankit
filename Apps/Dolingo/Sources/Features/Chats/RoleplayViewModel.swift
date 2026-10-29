import Foundation
import TitanCore
import TitanSpeech

/// Runs a scripted roleplay: the learner says one of the expected replies, the partner answers
/// with the next line, and the tasks the reply covers are ticked. Ends after the partner's goodbye.
@MainActor
final class RoleplayViewModel: ObservableObject {
    struct Message: Identifiable, Equatable {
        let id: Int
        let phrase: Phrase
        let isMine: Bool
    }

    enum State: Equatable {
        /// Waiting for the learner to speak.
        case ready
        case listening
        /// What the learner said matched no reply well enough.
        case missed(PronunciationScore)
        case finished
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var state: State = .ready
    @Published private(set) var completedTasks: Set<String> = []
    /// No microphone or speech permission: the learner sends the hint instead of speaking.
    @Published private(set) var isMicBlocked = false

    let roleplay: Roleplay
    let language: String
    private let speech: any SpeechRecognizer
    private let activity: ActivityStore?
    private let startedAt = Date()
    private var turn = 0
    private var hasPermission = false

    init(roleplay: Roleplay, language: String, speech: any SpeechRecognizer, activity: ActivityStore? = nil) {
        self.roleplay = roleplay
        self.language = language
        self.speech = speech
        self.activity = activity
        showPartnerLine()
    }

    /// The replies expected now; empty once the roleplay is over.
    var replies: [RoleplayReply] {
        roleplay.turns.indices.contains(turn) ? roleplay.turns[turn].replies : []
    }

    /// The reply the hint card suggests.
    var hint: RoleplayReply? { replies.first }

    var taskCount: Int { roleplay.tasks.count }

    var completedTaskCount: Int {
        roleplay.tasks.filter { completedTasks.contains($0.id) }.count
    }

    func isDone(_ task: RoleplayTask) -> Bool {
        completedTasks.contains(task.id)
    }

    /// The microphone button: listens, then sends the reply it matches.
    func speak() async {
        guard state != .listening, state != .finished, !isMicBlocked else { return }
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
            answer(heard)
        } catch {
            if error == .unauthorized { isMicBlocked = true }
            state = .ready
        }
    }

    func stopListening() {
        speech.stop()
    }

    /// Picks the reply closest to what was heard; sends it when it passes.
    func answer(_ heard: String) {
        let scored = replies.map { (reply: $0, score: PronunciationScore(expected: $0.text, heard: heard)) }
        guard let best = scored.max(by: { $0.score.value < $1.score.value }) else { return }
        activity?.recordSpoken(best.score)
        if best.score.verdict.isPass {
            send(best.reply)
        } else {
            state = .missed(best.score)
        }
    }

    /// Sends a reply as the learner's message, e.g. from the hint when the microphone is off.
    func send(_ reply: RoleplayReply) {
        guard replies.contains(reply) else { return }
        messages.append(Message(id: messages.count, phrase: reply.phrase, isMine: true))
        completedTasks.formUnion(reply.completes)
        turn += 1
        showPartnerLine()
    }

    private func showPartnerLine() {
        guard roleplay.turns.indices.contains(turn) else {
            finish()
            return
        }
        messages.append(Message(id: messages.count, phrase: roleplay.turns[turn].partner, isMine: false))
        if replies.isEmpty {
            finish()
        } else {
            state = .ready
        }
    }

    private func finish() {
        guard state != .finished else { return }
        state = .finished
        activity?.recordRoleplay(tasksDone: completedTaskCount, tasksTotal: taskCount,
                                 seconds: Date().timeIntervalSince(startedAt))
    }
}
