import Foundation
import TitanStorage

/// The Settings sheet of a lesson and of a roleplay (Figma 42 and 56), shared by all of them.
struct PracticeSettings: Codable, Equatable, Sendable {
    /// Speeds offered for the tutor's voice.
    static let speeds: [Double] = [0.5, 0.75, 1, 1.25, 1.5]

    /// Listen as soon as the tutor or partner has finished speaking.
    var autoMicrophone = true
    /// 1 is the normal pace.
    var playbackSpeed = 1.0
    /// The meaning under the phrase in lessons.
    var showSubtitles = true
    /// A sound and a tap when a phrase is scored.
    var soundEffects = true
    /// The 💡 suggestion in roleplays.
    var hints = true
    /// The partner's lines open with their meaning in roleplays.
    var translations = true
    /// The AI's corrected version under the learner's lines in roleplays with AI.
    var autoCorrections = false

    static func speedLabel(_ speed: Double) -> String {
        "\(String(format: "%g", speed))x"
    }
}

/// Keeps the practice settings in Preferences as they change.
@MainActor
final class PracticeSettingsStore: ObservableObject {
    @Published var settings: PracticeSettings {
        didSet { preferences.set(settings, for: DolingoKeys.practiceSettings) }
    }

    private let preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
        settings = preferences.value(DolingoKeys.practiceSettings)
    }
}
