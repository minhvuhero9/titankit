import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization
import TitanSpeech

/// Figma "learn a language": the tutor says a phrase, the user taps the microphone and says it
/// back, and gets "Perfect!", "Almost there!", "Oops.. Try again!" or "We can't hear you!".
/// Leaving early asks first; the end shows "Lesson completed" with time and accuracy.
struct LessonScreen: View {
    @ObservedObject var learning: LearningStore
    let speech: any SpeechRecognizer
    let lessonId: String
    let onClose: () -> Void

    var body: some View {
        if case let .loaded(course?) = learning.course, let lesson = course.lessons.first(where: { $0.id == lessonId }) {
            LessonPlayer(lesson: lesson, language: course.language, speech: speech, onClose: onClose) {
                learning.complete(lesson)
                onClose()
            }
        } else {
            TKLoadingView()
                .onAppear(perform: onClose)
        }
    }
}

private struct LessonPlayer: View {
    let onClose: () -> Void
    let onComplete: () -> Void

    @StateObject private var viewModel: LessonViewModel
    @State private var confirmingLeave = false
    @State private var speaker = PhraseSpeaker()
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    init(
        lesson: Lesson,
        language: String,
        speech: any SpeechRecognizer,
        onClose: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.onClose = onClose
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: LessonViewModel(lesson: lesson, language: language, speech: speech))
    }

    var body: some View {
        Group {
            if viewModel.isFinished {
                completed
            } else {
                player
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkSheet(isPresented: $confirmingLeave) {
            TKSheet(
                title: Text("lesson.leave.title"),
                primary: TKModalAction(title: Text("lesson.leave.confirm")) {
                    confirmingLeave = false
                    onClose()
                },
                secondary: TKModalAction(title: Text("lesson.leave.stay")) { confirmingLeave = false }
            ) {
                Text("lesson.leave.message")
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var player: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                TKNavBarButton(Image(tk: TKSymbol.multiply),
                               accessibilityLabel: KitStrings.string(KitStrings.Paywall.close, locale: locale)) {
                    confirmingLeave = true
                }
                TKProgressBar(value: viewModel.progress)
            }
            Spacer()
            TKAvatar(name: viewModel.lesson.tutor, size: 160)
            Text(verbatim: viewModel.lesson.tutor)
                .tkTextStyle(.headline)
                .foregroundStyle(theme.colors.textSecondary.color)
            if let phrase = viewModel.phrase {
                VStack(spacing: Spacing.xs) {
                    phraseText(phrase)
                        .tkTextStyle(.title2)
                    Text(verbatim: phrase.meaning.localized(languageCode))
                        .tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .multilineTextAlignment(.center)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .top) { resultBadge.offset(y: -Spacing.lg) }
                .id(viewModel.index)
                .transition(.opacity)
                TKButton("lesson.listen", style: .light, size: .medium, shape: .pill, leadingIcon: Image(tk: .volumeUp)) {
                    say(phrase)
                }
                .disabled(viewModel.attempt == .listening)
            }
            Spacer()
            controls
        }
        .padding(Spacing.lg)
        .onChange(of: viewModel.index) { _ in
            if let phrase = viewModel.phrase { say(phrase) }
        }
        .onAppear {
            if let phrase = viewModel.phrase { say(phrase) }
        }
    }

    /// Microphone while practising; Continue once the phrase passed; Skip after a miss.
    @ViewBuilder
    private var controls: some View {
        if viewModel.canContinue {
            if viewModel.isMicBlocked {
                Text("lesson.micBlocked")
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
            TKButton(Text.kit(KitStrings.continueAction, locale: locale), shape: .pill) {
                withAnimation { viewModel.next() }
            }
        } else {
            ZStack(alignment: .trailing) {
                MicrophoneButton(isListening: viewModel.attempt == .listening, ringColor: ringColor) {
                    if viewModel.attempt == .listening {
                        viewModel.stopListening()
                    } else {
                        speaker.stop()
                        Task { await viewModel.speak() }
                    }
                }
                .frame(maxWidth: .infinity)
                if viewModel.score != nil {
                    Button {
                        withAnimation { viewModel.next() }
                    } label: {
                        Text("lesson.skip")
                            .tkTextStyle(.headline)
                            .foregroundStyle(theme.colors.textSecondary.color)
                    }
                }
            }
        }
    }

    /// The phrase, with each word green once said or red when missed.
    private func phraseText(_ phrase: Phrase) -> Text {
        guard let score = viewModel.score, score.verdict != .notHeard else {
            return Text(verbatim: phrase.text).foregroundColor(theme.colors.textPrimary.color)
        }
        return score.words.enumerated().reduce(Text(verbatim: "")) { text, item in
            let color = item.element.isMatched ? theme.colors.feedbackSuccess : theme.colors.feedbackError
            let word = Text(verbatim: (item.offset == 0 ? "" : " ") + item.element.text).foregroundColor(color.color)
            return text + word
        }
    }

    /// Figma result bubble: an emoji over "Perfect! (100%)" and the like.
    @ViewBuilder
    private var resultBadge: some View {
        if let score = viewModel.score {
            VStack(spacing: Spacing.xxs) {
                Text(verbatim: Self.emoji(score.verdict))
                    .font(.system(size: 28))
                    .accessibilityHidden(true)
                Self.verdictText(score)
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(theme.colors.surfaceBackground.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var ringColor: Color {
        switch viewModel.score?.verdict {
        case .perfect?, .almostThere?: theme.colors.feedbackSuccess.color
        case .tryAgain?: theme.colors.feedbackError.color
        case .notHeard?, nil: theme.colors.border.color
        }
    }

    private func say(_ phrase: Phrase) {
        speaker.say(phrase.text, language: viewModel.language)
    }

    static func emoji(_ verdict: PronunciationScore.Verdict) -> String {
        switch verdict {
        case .perfect: "😄"
        case .almostThere: "🙂"
        case .tryAgain: "😟"
        case .notHeard: "😶"
        }
    }

    static func verdictText(_ score: PronunciationScore) -> Text {
        switch score.verdict {
        case .perfect: Text("lesson.result.perfect \(score.percent)")
        case .almostThere: Text("lesson.result.almost \(score.percent)")
        case .tryAgain: Text("lesson.result.tryAgain")
        case .notHeard: Text("lesson.result.notHeard")
        }
    }

    private var completed: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            Text(verbatim: "🏆")
                .font(.system(size: 120))
                .accessibilityHidden(true)
            Text("lesson.completed.title")
                .tkTextStyle(.title1)
                .foregroundStyle(theme.colors.textPrimary.color)
            HStack(spacing: Spacing.md) {
                statCard(title: Text("lesson.completed.time"), value: LessonViewModel.formatted(viewModel.duration),
                         color: theme.colors.feedbackSuccess)
                if let accuracy = viewModel.accuracy {
                    statCard(title: Text("lesson.completed.accuracy"), value: "\(Int((accuracy * 100).rounded()))%",
                             color: theme.colors.feedbackError)
                } else {
                    statCard(title: Text("lesson.completed.phrases"), value: "\(viewModel.lesson.phrases.count)",
                             color: theme.colors.actionPrimary)
                }
            }
            Spacer()
            TKButton(Text.kit(KitStrings.continueAction, locale: locale), shape: .pill, action: onComplete)
        }
        .padding(Spacing.lg)
    }

    /// Figma "Time" and "Accuracy" cards: a coloured title strip over the value.
    private func statCard(title: Text, value: String, color: AdaptiveColor) -> some View {
        VStack(spacing: 0) {
            title
                .tkTextStyle(.caption)
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(color.color)
            Text(verbatim: value)
                .tkTextStyle(.title2)
                .foregroundStyle(theme.colors.textPrimary.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(color.color, lineWidth: 2))
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "vi"
    }
}
