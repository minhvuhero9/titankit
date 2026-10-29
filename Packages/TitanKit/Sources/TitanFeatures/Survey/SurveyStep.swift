import SwiftUI

/// One answer the user can pick in a survey step.
public struct SurveyOption: Identifiable {
    public let id: String
    public var title: Text
    public var detail: Text?
    let leading: AnyView?

    /// - Parameter icon: shown 48 pt on the left of the card, e.g. a flag or a colour icon.
    @MainActor
    public init(_ id: String, title: Text, detail: Text? = nil, icon: Image? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        leading = icon.map { AnyView($0.resizable().scaledToFit().frame(width: 48, height: 48)) }
    }

    /// An emoji in place of the icon, e.g. a flag: "🇪🇸".
    @MainActor
    public init(_ id: String, title: Text, detail: Text? = nil, emoji: String) {
        self.id = id
        self.title = title
        self.detail = detail
        leading = AnyView(Text(verbatim: emoji).font(.system(size: 36)).frame(width: 48, height: 48).accessibilityHidden(true))
    }
}

/// What the user answered in one step, saved by the app.
public enum SurveyAnswer: Codable, Sendable, Equatable {
    /// Ids of the picked options.
    case options([String])
    /// A time of day, e.g. the study reminder.
    case time(hour: Int, minute: Int)

    public var optionIds: [String] {
        if case let .options(ids) = self { return ids }
        return []
    }
}

/// One question of a `SurveyScreen`.
///
///     SurveyStep("level", kind: .single(levels)) { answers in
///         Text("survey.level.title \(languageName(answers["language"]))")
///     }
public struct SurveyStep: Identifiable {
    public enum Kind {
        /// Cards, one answer.
        case single([SurveyOption])
        /// Cards, any number of answers.
        case multiple([SurveyOption])
        /// Chips that wrap, any number of answers.
        case chips([SurveyOption])
        /// A wheel to pick a time, starting at `hour:minute`.
        case time(hour: Int, minute: Int)
    }

    public let id: String
    public var kind: Kind
    /// Small line under the answers, e.g. "You can always change this later."
    public var footnote: Text?
    private let makeTitle: ([String: SurveyAnswer]) -> Text

    public init(_ id: String, title: Text, kind: Kind, footnote: Text? = nil) {
        self.init(id, kind: kind, footnote: footnote) { _ in title }
    }

    /// A title that depends on earlier answers, e.g. the language picked in the first step.
    public init(_ id: String, kind: Kind, footnote: Text? = nil, title: @escaping ([String: SurveyAnswer]) -> Text) {
        self.id = id
        self.kind = kind
        self.footnote = footnote
        makeTitle = title
    }

    public func title(for answers: [String: SurveyAnswer]) -> Text {
        makeTitle(answers)
    }

    var options: [SurveyOption] {
        switch kind {
        case let .single(options), let .multiple(options), let .chips(options): options
        case .time: []
        }
    }

    var allowsManyAnswers: Bool {
        switch kind {
        case .multiple, .chips: true
        case .single, .time: false
        }
    }
}
