import AVFoundation
import Foundation
import Speech
import TitanCore

/// SpeechRecognizer on Apple's Speech framework. Recognises on the device when it can, so the
/// voice stays on the phone. The app needs NSMicrophoneUsageDescription and
/// NSSpeechRecognitionUsageDescription in its Info.plist.
public final class AppleSpeechRecognizer: SpeechRecognizer, @unchecked Sendable {
    // @unchecked: every mutable property is guarded by `lock`. The class is not tied to the
    // main actor because the audio tap and the recognition callbacks run on their own threads.
    private let lock = NSLock()
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: CheckedContinuation<String, Never>?
    private var heard = ""
    private var lastChange = Date()

    /// How long a pause ends the answer once the user has said something.
    private let silence: TimeInterval

    public init(silence: TimeInterval = 1.5) {
        self.silence = silence
    }

    public func requestAuthorization() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        if #available(iOS 17, *) {
            return await AVAudioApplication.requestRecordPermission()
        }
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
        }
    }

    public func transcribe(language: String, timeout: Duration) async throws(TitanError) -> String {
        stop()
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else { throw .unauthorized }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)), recognizer.isAvailable else {
            throw .unknown("speech recognition unavailable for \(language)")
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw .unknown("audio session: \(error.localizedDescription)")
        }

        let deadline = Date().addingTimeInterval(Double(timeout.components.seconds))
        let text = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
                lock.withLock {
                    self.continuation = continuation
                    heard = ""
                    lastChange = Date()
                }
                if !start(recognizer) { finish() }
                watch(until: deadline)
            }
        } onCancel: {
            finish()
        }
        return text
    }

    public func stop() {
        finish()
    }

    /// Starts the microphone and recognition. False when the audio engine can't start.
    private func start(_ recognizer: SFSpeechRecognizer) -> Bool {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        let sink = AudioSink(request: request)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            sink.request.append(buffer)
        }
        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                lock.withLock {
                    heard = result.bestTranscription.formattedString
                    lastChange = Date()
                }
                if result.isFinal { finish() }
            } else if error != nil {
                finish()
            }
        }
        lock.withLock {
            self.request = request
            self.task = task
        }
        engine.prepare()
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    /// Ends listening after a pause once something was heard, or at the deadline.
    private func watch(until deadline: Date) {
        Task { [weak self] in
            while let self {
                try? await Task.sleep(for: .milliseconds(250))
                let (isListening, done) = lock.withLock { () -> (Bool, Bool) in
                    let paused = !heard.isEmpty && Date().timeIntervalSince(lastChange) > silence
                    return (continuation != nil, paused || Date() >= deadline)
                }
                guard isListening else { return }
                if done {
                    finish()
                    return
                }
            }
        }
    }

    /// Stops the microphone and hands back what was heard. Safe to call more than once.
    private func finish() {
        let (continuation, request, task, text) = lock.withLock {
            let taken = (self.continuation, self.request, self.task, heard)
            self.continuation = nil
            self.request = nil
            self.task = nil
            return taken
        }
        if engine.isRunning {
            engine.stop()
        }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        continuation?.resume(returning: text)
    }
}

/// Hands microphone buffers to the recognition request from the audio thread.
/// The request is built to be fed from that thread.
private final class AudioSink: @unchecked Sendable {
    let request: SFSpeechAudioBufferRecognitionRequest

    init(request: SFSpeechAudioBufferRecognitionRequest) {
        self.request = request
    }
}
