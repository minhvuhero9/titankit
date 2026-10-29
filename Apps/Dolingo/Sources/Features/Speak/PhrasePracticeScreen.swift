import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization
import TitanSpeech

/// Figma "speaking practice": a card with the phrase, its meaning, play and slow play, the score
/// ring and a bookmark; under it previous, the microphone and next. Leaving asks first.
struct PhrasePracticeScreen: View {
    @ObservedObject var saved: SavedPhrases
    let onClose: () -> Void

    @StateObject private var viewModel: PhrasePracticeViewModel
    @State private var speaker = PhraseSpeaker()
    @State private var confirmingLeave = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    init(category: PhraseCategory, saved: SavedPhrases, speech: any SpeechRecognizer, onClose: @escaping () -> Void) {
        self.saved = saved
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: PhrasePracticeViewModel(
            category: category, language: AppConfig.learningLanguage, speech: speech
        ))
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                TKNavBarButton(Image(tk: TKSymbol.multiply),
                               accessibilityLabel: KitStrings.string(KitStrings.Paywall.close, locale: locale)) {
                    confirmingLeave = true
                }
                TKProgressBar(value: viewModel.progress)
            }
            if let phrase = viewModel.phrase {
                card(phrase)
            }
            Spacer(minLength: 0)
            HStack {
                arrow(Image(tk: .arrowLeft), label: "speak.previous", enabled: viewModel.canGoBack) { viewModel.previous() }
                Spacer()
                MicrophoneButton(isListening: viewModel.attempt == .listening, ringColor: ringColor) {
                    if viewModel.attempt == .listening {
                        viewModel.stopListening()
                    } else {
                        speaker.stop()
                        Task { await viewModel.speak() }
                    }
                }
                .disabled(viewModel.isMicBlocked)
                Spacer()
                arrow(Image(tk: .arrowRight), label: "speak.next", enabled: viewModel.canGoForward) { viewModel.next() }
            }
            if viewModel.isMicBlocked {
                Text("lesson.micBlocked")
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.lg)
        .background(theme.colors.surfaceCard.color.ignoresSafeArea())
        .onChange(of: viewModel.index) { _ in say() }
        .onAppear(perform: say)
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

    private func card(_ phrase: Phrase) -> some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Spacer()
                Button { saved.toggle(phrase) } label: {
                    Image(tk: .bookmark, style: saved.contains(phrase) ? .bold : .light)
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle((saved.contains(phrase) ? theme.colors.actionPrimary : theme.colors.textSecondary).color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(LocalizedStringKey(saved.contains(phrase) ? "speak.unsave" : "speak.save")))
            }
            VStack(spacing: Spacing.xs) {
                phraseText(phrase)
                    .tkTextStyle(.title2)
                Text(verbatim: phrase.meaning.localized(languageCode))
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .multilineTextAlignment(.center)
            HStack(spacing: Spacing.md) {
                listenButton(Image(tk: .volumeUp), label: "speak.play") { speaker.say(phrase.text, language: viewModel.language) }
                Rectangle()
                    .fill(theme.colors.border.color)
                    .frame(height: 2)
                listenButton(Text(verbatim: "🐢"), label: "speak.playSlow") {
                    speaker.say(phrase.text, language: viewModel.language, slow: true)
                }
            }
            scoreRing
        }
        .padding(Spacing.lg)
        .background(theme.colors.surfaceBackground.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .id(viewModel.index)
        .transition(.opacity)
    }

    /// Figma result: the percentage in a ring and the verdict under it.
    private var scoreRing: some View {
        let score = viewModel.score
        return VStack(spacing: Spacing.sm) {
            ZStack {
                Circle().stroke(theme.colors.border.color, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: score?.value ?? 0)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(verbatim: "\(score?.percent ?? 0)%")
                    .tkTextStyle(.title2)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
            .frame(width: 112, height: 112)
            .animation(.easeOut(duration: 0.4), value: score?.value)
            if let score {
                verdict(score)
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func verdict(_ score: PronunciationScore) -> Text {
        switch score.verdict {
        case .perfect: Text("speak.result.perfect")
        case .almostThere: Text("speak.result.almost")
        case .tryAgain: Text("lesson.result.tryAgain")
        case .notHeard: Text("lesson.result.notHeard")
        }
    }

    private var ringColor: Color {
        switch viewModel.score?.verdict {
        case .perfect?, .almostThere?: theme.colors.actionPrimary.color
        case .tryAgain?: theme.colors.feedbackError.color
        case .notHeard?, nil: theme.colors.border.color
        }
    }

    /// The phrase, brand-coloured when said well and red when not.
    private func phraseText(_ phrase: Phrase) -> Text {
        let color: AdaptiveColor = switch viewModel.score?.verdict {
        case .perfect?, .almostThere?: theme.colors.actionPrimary
        case .tryAgain?: theme.colors.feedbackError
        case .notHeard?, nil: theme.colors.textPrimary
        }
        return Text(verbatim: phrase.text).foregroundColor(color.color)
    }

    private func listenButton(_ icon: some View, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .frame(width: 28, height: 28)
                .foregroundStyle(theme.colors.textPrimary.color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private func arrow(_ icon: Image, label: LocalizedStringKey, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation { action() } }) {
            icon
                .resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(theme.colors.textPrimary.color)
                .frame(width: 52, height: 52)
                .overlay(Circle().stroke(theme.colors.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(Text(label))
    }

    private func say() {
        if let phrase = viewModel.phrase { speaker.say(phrase.text, language: viewModel.language) }
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "vi"
    }
}
