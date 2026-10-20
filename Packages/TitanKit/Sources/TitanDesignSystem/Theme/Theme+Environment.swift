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
    /// Apply once at the root: every TK component below reads this theme.
    func titanTheme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
            .tint(theme.colors.actionPrimary.color)
    }

    /// Font, line spacing and letter spacing for a text role, taken from the current theme.
    func tkTextStyle(_ role: TextRole) -> some View {
        modifier(TextStyleModifier(role: role))
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
