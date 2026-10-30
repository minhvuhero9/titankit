import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "learn a language - settings" and "roleplay chat - settings": switches for the
/// practice, the voice speed, and Help & Feedback, which writes to support.
struct PracticeSettingsSheet: View {
    enum Kind {
        case lesson
        case roleplay
        /// A roleplay played with the AI, which can also correct the learner.
        case aiRoleplay
    }

    let kind: Kind
    @ObservedObject var store: PracticeSettingsStore
    let onClose: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("practice.settings")
                    .tkTextStyle(.title3)
                    .foregroundStyle(theme.colors.textPrimary.color)
                HStack {
                    Spacer()
                    TKNavBarButton(Image(tk: TKSymbol.multiply),
                                   accessibilityLabel: KitStrings.string("practice.close", locale: locale), action: onClose)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            TKDivider()
            ScrollView {
                VStack(spacing: 0) {
                    if kind != .lesson {
                        toggle("practice.autoMicrophone", \.autoMicrophone)
                    }
                    speedRow
                    if kind == .lesson {
                        toggle("practice.autoMicrophone", \.autoMicrophone)
                        toggle("practice.subtitles", \.showSubtitles)
                    } else {
                        toggle("practice.hints", \.hints)
                        toggle("practice.translations", \.translations)
                        if kind == .aiRoleplay {
                            toggle("practice.corrections", \.autoCorrections)
                        }
                    }
                    toggle("practice.soundEffects", \.soundEffects)
                    TKSettingsRow("practice.help", accessory: .none) {
                        let subject = "Dolingo feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "mailto:\(AppConfig.supportEmail)?subject=\(subject)") { openURL(url) }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
    }

    private func toggle(_ title: LocalizedStringKey, _ keyPath: WritableKeyPath<PracticeSettings, Bool>) -> some View {
        VStack(spacing: 0) {
            TKSettingsRow(title, accessory: .toggle(Binding(
                get: { store.settings[keyPath: keyPath] },
                set: { store.settings[keyPath: keyPath] = $0 }
            )))
            TKDivider()
        }
    }

    /// "Playback Speed 1x ⌄": a menu of the speeds.
    private var speedRow: some View {
        VStack(spacing: 0) {
            Menu {
                Picker(selection: Binding(get: { store.settings.playbackSpeed },
                                          set: { store.settings.playbackSpeed = $0 })) {
                    ForEach(PracticeSettings.speeds, id: \.self) { speed in
                        Text(verbatim: PracticeSettings.speedLabel(speed)).tag(speed)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                HStack {
                    Text(LocalizedStringKey(kind == .lesson ? "practice.speed" : "practice.audioSpeed"))
                        .tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textPrimary.color)
                    Spacer()
                    Text(verbatim: PracticeSettings.speedLabel(store.settings.playbackSpeed))
                        .tkTextStyle(.callout)
                        .foregroundStyle(theme.colors.textSecondary.color)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            TKDivider()
        }
    }
}
