import Foundation

/// Walks through the survey steps and keeps the answers.
@MainActor
public final class SurveyViewModel: ObservableObject {
    @Published public private(set) var index = 0
    @Published public private(set) var answers: [String: SurveyAnswer]

    public let steps: [SurveyStep]

    /// - Parameter answers: earlier answers, e.g. when the user comes back to the survey.
    public init(steps: [SurveyStep], answers: [String: SurveyAnswer] = [:]) {
        precondition(!steps.isEmpty, "A survey needs at least one step")
        self.steps = steps
        self.answers = answers
    }

    public var step: SurveyStep { steps[index] }

    /// From 1 / count on the first step to 1 on the last, for the progress bar.
    public var progress: Double {
        Double(index + 1) / Double(steps.count)
    }

    public func isSelected(_ optionId: String) -> Bool {
        answers[step.id]?.optionIds.contains(optionId) ?? false
    }

    /// Picks the option on a one-answer step; turns it on or off on a many-answer step.
    public func select(_ optionId: String) {
        guard step.options.contains(where: { $0.id == optionId }) else { return }
        var ids = answers[step.id]?.optionIds ?? []
        if !step.allowsManyAnswers {
            ids = [optionId]
        } else if let position = ids.firstIndex(of: optionId) {
            ids.remove(at: position)
        } else {
            ids.append(optionId)
        }
        answers[step.id] = .options(ids)
    }

    /// The time shown on a time step: the saved answer, else the step's starting time.
    public var time: (hour: Int, minute: Int) {
        if case let .time(hour, minute)? = answers[step.id] { return (hour, minute) }
        if case let .time(hour, minute) = step.kind { return (hour, minute) }
        return (0, 0)
    }

    public func setTime(hour: Int, minute: Int) {
        guard case .time = step.kind else { return }
        answers[step.id] = .time(hour: hour, minute: minute)
    }

    /// A time step always has an answer; the others need at least one option picked.
    public var canContinue: Bool {
        if case .time = step.kind { return true }
        return !(answers[step.id]?.optionIds.isEmpty ?? true)
    }

    /// Goes to the next step. True when the last step was answered and the survey is done.
    public func next() -> Bool {
        guard canContinue else { return false }
        if case .time = step.kind, answers[step.id] == nil {
            answers[step.id] = .time(hour: time.hour, minute: time.minute)
        }
        guard index < steps.count - 1 else { return true }
        index += 1
        return false
    }

    /// Goes to the previous step. False on the first step, where back leaves the survey.
    public func back() -> Bool {
        guard index > 0 else { return false }
        index -= 1
        return true
    }
}
