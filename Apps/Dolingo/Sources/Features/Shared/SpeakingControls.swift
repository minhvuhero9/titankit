import AVFoundation
import SwiftUI
import TitanDesignSystem
import TitanIcons

/// Reads a phrase aloud with the system voice for the course language.
@MainActor
final class PhraseSpeaker {
    private let synthesizer = AVSpeechSynthesizer()

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// - Parameter slow: the snail button, for hearing every sound.
    func say(_ text: String, language: String, slow: Bool = false) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * (slow ? 0.55 : 0.9)
        synthesizer.speak(utterance)
    }
}

/// Figma microphone: a brand circle, a ring around it that turns while listening and takes the
/// result colour afterwards, and "Tap to speak" / "Listening..." under it.
struct MicrophoneButton: View {
    let isListening: Bool
    let ringColor: Color
    let action: () -> Void

    @State private var turn = false
    @Environment(\.theme) private var theme

    private var label: LocalizedStringKey {
        isListening ? "lesson.listening" : "lesson.tapToSpeak"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(isListening ? theme.colors.actionPrimary.color : ringColor,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(turn ? 360 : 135))
                        .frame(width: 104, height: 104)
                    Circle()
                        .fill(theme.gradientPrimary.linearGradient)
                        .frame(width: 80, height: 80)
                    Image(tk: .voice, style: .bold)
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(theme.colors.actionOnPrimary.color)
                }
                Text(label)
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .onChange(of: isListening) { listening in
            if listening {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { turn = true }
            } else {
                withAnimation(.default) { turn = false }
            }
        }
    }
}
