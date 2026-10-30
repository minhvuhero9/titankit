import AVFoundation
import AudioToolbox
import SwiftUI
import TitanDesignSystem
import TitanIcons
import UIKit

/// Reads a phrase aloud with the system voice for the course language.
@MainActor
final class PhraseSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func stop() {
        onFinish = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// - Parameters:
    ///   - slow: the snail button, for hearing every sound.
    ///   - speed: the playback speed from the practice settings, 1 for the normal pace.
    ///   - onFinish: called when the phrase has been said to the end, not when it is stopped.
    func say(_ text: String, language: String, slow: Bool = false, speed: Double = 1, onFinish: (() -> Void)? = nil) {
        stop()
        self.onFinish = onFinish
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        let rate = AVSpeechUtteranceDefaultSpeechRate * Float(slow ? 0.55 : 0.9) * Float(speed)
        utterance.rate = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        synthesizer.speak(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let finished = self.onFinish
            self.onFinish = nil
            finished?()
        }
    }
}

/// The sound and tap of the "Play Sound Effects" setting.
@MainActor
enum PracticeSound {
    static func play(success: Bool) {
        AudioServicesPlaySystemSound(success ? 1057 : 1053)
        UINotificationFeedbackGenerator().notificationOccurred(success ? .success : .error)
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
