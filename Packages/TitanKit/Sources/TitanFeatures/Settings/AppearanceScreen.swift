import SwiftUI
import TitanDesignSystem
import TitanLocalization

/// Figma "App Appearance": Theme and App Language, each opening a sheet of choices.
///
///     @Preference(AppKeys.appearance) var appearance
///     AppearanceScreen(appearance: $appearance, localization: container.localization,
///                      onBack: { router.pop() })
///
/// The app applies the theme at its root with `.tkAppearance(appearance)`.
/// The language changes through `LocalizationService`, which redraws the app.
public struct AppearanceScreen: View {
    private enum Choice: Identifiable {
        case theme, language
        var id: Self { self }
    }

    @Binding private var appearance: TKAppearance
    @ObservedObject private var localization: LocalizationService
    private let onBack: (() -> Void)?

    @State private var choice: Choice?
    @State private var draftAppearance: TKAppearance = .system
    @State private var draftLanguage = Language("vi")
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    public init(appearance: Binding<TKAppearance>, localization: LocalizationService, onBack: (() -> Void)? = nil) {
        _appearance = appearance
        _localization = ObservedObject(wrappedValue: localization)
        self.onBack = onBack
    }

    /// Kit string key of each theme choice.
    public nonisolated static func titleKey(for appearance: TKAppearance) -> String {
        switch appearance {
        case .system: KitStrings.Settings.themeSystem
        case .light: KitStrings.Settings.themeLight
        case .dark: KitStrings.Settings.themeDark
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xs) {
                TKSettingsRow(
                    title: kit(KitStrings.Settings.theme),
                    accessory: .value(kit(Self.titleKey(for: appearance)))
                ) {
                    draftAppearance = appearance
                    choice = .theme
                }
                TKSettingsRow(
                    title: kit(KitStrings.Settings.language),
                    accessory: .value(Text(verbatim: localization.currentLanguage.displayName))
                ) {
                    draftLanguage = localization.currentLanguage
                    choice = .language
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, Spacing.sm)
            .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: kit(KitStrings.Settings.appearance), onBack: onBack)
        .tkSheet(isPresented: isChoosing) {
            switch choice {
            case .theme?: themeSheet
            case .language?: languageSheet
            case nil: EmptyView()
            }
        }
    }

    private var isChoosing: Binding<Bool> {
        Binding(get: { choice != nil }, set: { if !$0 { choice = nil } })
    }

    private var themeSheet: some View {
        TKSheet(
            title: kit(KitStrings.Settings.chooseTheme),
            primary: TKModalAction(title: kit(KitStrings.ok)) {
                appearance = draftAppearance
                choice = nil
            },
            secondary: cancel
        ) {
            TKRadioGroup(selection: $draftAppearance, options: TKAppearance.allCases.map {
                TKOption($0, title: kit(Self.titleKey(for: $0)))
            })
        }
    }

    private var languageSheet: some View {
        TKSheet(
            title: kit(KitStrings.Settings.chooseLanguage),
            primary: TKModalAction(title: kit(KitStrings.ok)) {
                choice = nil
                localization.setLanguage(draftLanguage)
            },
            secondary: cancel
        ) {
            TKRadioGroup(selection: $draftLanguage, options: localization.supportedLanguages.map {
                TKOption($0, title: Text(verbatim: $0.displayName))
            })
        }
    }

    private var cancel: TKModalAction {
        TKModalAction(title: kit(KitStrings.cancel)) { choice = nil }
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}
