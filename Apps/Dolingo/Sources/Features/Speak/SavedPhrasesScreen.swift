import SwiftUI
import TitanDesignSystem
import TitanIcons

/// Figma "speak - saved phrases": the bookmarked phrases with their meaning, a play button on
/// each, and one at the bottom that plays them all in turn.
struct SavedPhrasesScreen: View {
    @ObservedObject var saved: SavedPhrases
    let onBack: () -> Void

    @State private var speaker = PhraseSpeaker()
    @State private var playingAll: Task<Void, Never>?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            if saved.phrases.isEmpty {
                TKEmptyState(icon: Image(tk: .bookmark), title: "speak.saved.empty.title", message: "speak.saved.empty.message")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(saved.phrases, id: \.self) { phrase in
                        row(phrase)
                    }
                    .onDelete { offsets in
                        offsets.map { saved.phrases[$0] }.forEach(saved.toggle)
                    }
                }
                .listStyle(.plain)
                .overlay(alignment: .bottomTrailing) { playAllButton }
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar("speak.saved", onBack: onBack)
        .onDisappear {
            playingAll?.cancel()
            speaker.stop()
        }
    }

    private func row(_ phrase: Phrase) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: phrase.text)
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(verbatim: phrase.meaning.localized(locale.language.languageCode?.identifier ?? "vi"))
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button { speaker.say(phrase.text, language: AppConfig.learningLanguage) } label: {
                Image(tk: .volumeUp)
                    .resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(theme.colors.border.color, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("speak.play"))
        }
        .padding(.vertical, Spacing.xs)
        .listRowBackground(theme.colors.surfaceBackground.color)
    }

    private var playAllButton: some View {
        Button {
            if let playingAll {
                playingAll.cancel()
                self.playingAll = nil
                speaker.stop()
            } else {
                playingAll = Task { await playAll() }
            }
        } label: {
            Image(systemName: playingAll == nil ? "play.fill" : "stop.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .frame(width: 60, height: 60)
                .background(theme.colors.actionPrimary.color, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(Spacing.lg)
        .accessibilityLabel(Text(LocalizedStringKey(playingAll == nil ? "speak.playAll" : "speak.stop")))
    }

    /// Reads every saved phrase with a pause after each.
    private func playAll() async {
        for phrase in saved.phrases {
            speaker.say(phrase.text, language: AppConfig.learningLanguage)
            let seconds = 1.5 + Double(phrase.text.split(separator: " ").count) * 0.45
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
        }
        playingAll = nil
    }
}
