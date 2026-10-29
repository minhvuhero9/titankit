import AVFoundation
import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "learn a language - learn with tutor": close, progress, the tutor, the phrase with its
/// meaning, "Listen" and Continue. Leaving early asks first; the end shows "Lesson completed".
/// Speaking practice with a score comes with the speech recognition step.
struct LessonScreen: View {
    @ObservedObject var learning: LearningStore
    let lessonId: String
    let onClose: () -> Void

    var body: some View {
        if case let .loaded(course?) = learning.course, let lesson = course.lessons.first(where: { $0.id == lessonId }) {
            LessonPlayer(lesson: lesson, language: course.language, onClose: onClose) {
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
    let language: String
    let onClose: () -> Void
    let onComplete: () -> Void

    @StateObject private var viewModel: LessonViewModel
    @State private var confirmingLeave = false
    @State private var speaker = PhraseSpeaker()
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    init(lesson: Lesson, language: String, onClose: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.language = language
        self.onClose = onClose
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: LessonViewModel(lesson: lesson))
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
                    Text(verbatim: phrase.text)
                        .tkTextStyle(.title2)
                        .foregroundStyle(theme.colors.textPrimary.color)
                    Text(verbatim: phrase.meaning.localized(languageCode))
                        .tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .multilineTextAlignment(.center)
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .id(viewModel.index)
                .transition(.opacity)
                TKButton("lesson.listen", style: .light, size: .medium, shape: .pill, leadingIcon: Image(tk: .volumeUp)) {
                    speaker.say(phrase.text, language: language)
                }
            }
            Spacer()
            TKButton(Text.kit(KitStrings.continueAction, locale: locale), shape: .pill) {
                withAnimation { viewModel.next() }
            }
        }
        .padding(Spacing.lg)
        .onChange(of: viewModel.index) { _ in
            if let phrase = viewModel.phrase { speaker.say(phrase.text, language: language) }
        }
        .onAppear {
            if let phrase = viewModel.phrase { speaker.say(phrase.text, language: language) }
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
                statCard(title: Text("lesson.completed.phrases"), value: "\(viewModel.lesson.phrases.count)",
                         color: theme.colors.actionPrimary)
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

/// Reads a phrase aloud with the system voice for the course language.
@MainActor
final class PhraseSpeaker {
    private let synthesizer = AVSpeechSynthesizer()

    func say(_ text: String, language: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }
}
