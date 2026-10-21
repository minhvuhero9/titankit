import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.base
}

public extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

public extension View {
    /// Apply once at the root, below where the app sets `\.locale`: every TK component below
    /// reads this theme, with the font family picked for the current language.
    func titanTheme(_ theme: Theme) -> some View {
        modifier(ThemeRoot(theme: theme))
    }

    /// Font, line spacing and letter spacing for a text role, taken from the current theme.
    func tkTextStyle(_ role: TextRole) -> some View {
        modifier(TextStyleModifier(role: role))
    }
}

private struct ThemeRoot: ViewModifier {
    let theme: Theme
    @Environment(\.locale) private var locale

    init(theme: Theme) {
        TKFonts.registerBundledFonts()
        self.theme = theme
    }

    func body(content: Content) -> some View {
        var localized = theme
        localized.typography = theme.typography.localized(for: locale)
        return content
            .environment(\.theme, localized)
            .tint(theme.colors.actionPrimary.color)
    }
}

private struct TextStyleModifier: ViewModifier {
    let role: TextRole
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.font(role))
            .lineSpacing(theme.typography.lineSpacing(role))
            .tracking(theme.typography.style(role).tracking)
    }
}
