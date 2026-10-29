import Foundation
import TitanCore

/// SpeechRecognizer for tests, previews and the simulator, which has no microphone input.
///
///     let speech = MockSpeechRecognizer(transcripts: ["hola", ""])
///     speech.isAuthorized = false
public final class MockSpeechRecognizer: SpeechRecognizer, @unchecked Sendable {
    // @unchecked: all state is guarded by `lock`.
    private let lock = NSLock()
    private var queue: [String]
    private var authorized: Bool
    private var error: TitanError?
    private var languages: [String] = []

    /// - Parameter transcripts: returned one per `transcribe` call; the last one repeats.
    public init(transcripts: [String] = [""], isAuthorized: Bool = true) {
        queue = transcripts
        authorized = isAuthorized
    }

    public func requestAuthorization() async -> Bool {
        lock.withLock { authorized }
    }

    public func transcribe(language: String, timeout: Duration) async throws(TitanError) -> String {
        let (authorized, error, text): (Bool, TitanError?, String) = lock.withLock {
            languages.append(language)
            let text = queue.count > 1 ? queue.removeFirst() : (queue.first ?? "")
            return (self.authorized, self.error, text)
        }
        guard authorized else { throw .unauthorized }
        if let error { throw error }
        return text
    }

    public func stop() {}

    // MARK: - Controls for tests

    public var isAuthorized: Bool {
        get { lock.withLock { authorized } }
        set { lock.withLock { authorized = newValue } }
    }

    /// Thrown by `transcribe` until set back to nil.
    public func failCalls(with error: TitanError?) {
        lock.withLock { self.error = error }
    }

    /// Languages asked for, in order.
    public var requestedLanguages: [String] {
        lock.withLock { languages }
    }
}
