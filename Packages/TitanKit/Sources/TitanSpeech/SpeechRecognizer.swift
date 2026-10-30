import Foundation
import TitanCore

/// Turns what the user says into text.
///
///     guard await speech.requestAuthorization() else { showPermissionHint(); return }
///     let heard = try await speech.transcribe(language: "es", timeout: .seconds(8))
///     let score = PronunciationScore(expected: "Encantado de conocerte", heard: heard)
public protocol SpeechRecognizer: Sendable {
    /// Asks for the microphone and speech recognition. False when either is refused.
    func requestAuthorization() async -> Bool

    /// Listens until the user stops talking, `timeout` runs out or `stop()` is called,
    /// then returns what was heard; empty when nothing was.
    /// Throws `.unauthorized` without permission and `.unknown` when recognition can't start.
    func transcribe(language: String, timeout: Duration) async throws(TitanError) -> String

    /// Ends the current `transcribe` early with what was heard so far.
    func stop()
}
