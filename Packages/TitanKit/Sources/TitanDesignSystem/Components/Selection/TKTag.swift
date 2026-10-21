import SwiftUI

/// Figma "Tag": a small non-interactive label, e.g. "Mới", "Đã xong", "Hết hạn".
///
///     TKTag("Mới", tone: .info)
///     TKTag("Hết hạn", tone: .error, style: .outline, size: .small)
public struct TKTag: View {
    /// What the tag says about its item. Picks the colour.
    public enum Tone: String, CaseIterable, Sendable {
        case neutral, info, success, warning, error
    }

    public enum Style: String, CaseIterable, Sendable {
        /// Coloured fill, white text.
        case solid
        /// Light tint of the colour behind coloured text.
        case soft
        /// Coloured border and text.
        case outline
        /// Coloured text only.
        case plain
    }

    public enum Size: String, CaseIterable, Sendable {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: 10
            case .medium: 12
            case .large: 14
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            case .medium: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            case .large: EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: 4
            case .medium: 6
            case .large: 8
            }
        }

        var borderWidth: CGFloat { self == .large ? 2 : 1.5 }
    }

    private let title: Text
    private let tone: Tone
    private let style: Style
    private let size: Size

    @Environment(\.theme) private var theme

    public init(_ title: LocalizedStringKey, tone: Tone = .neutral, style: Style = .soft, size: Size = .medium) {
        self.init(title: Text(title), tone: tone, style: style, size: size)
    }

    public init(title: Text, tone: Tone = .neutral, style: Style = .soft, size: Size = .medium) {
        self.title = title
        self.tone = tone
        self.style = style
        self.size = size
    }

    public var body: some View {
        let look = TKTagColors.resolve(tone: tone, style: style, colors: theme.colors)
        let shape = RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
        title
            .font(theme.typography.font(size: size.fontSize, weight: .semibold, relativeTo: .caption))
            .tracking(0.2)
            .lineLimit(1)
            .foregroundStyle(look.foreground.color)
            .padding(size.padding)
            .background { if let fill = look.background { shape.fill(fill.color) } }
            .overlay { if look.hasBorder { shape.strokeBorder(look.foreground.color, lineWidth: size.borderWidth) } }
    }
}

/// Colours of a tag. Kept apart from the view so it can be tested.
struct TKTagColors: Equatable {
    var background: AdaptiveColor?
    var foreground: AdaptiveColor
    var hasBorder = false

    static func toneColor(_ tone: TKTag.Tone, colors: ColorTokens) -> AdaptiveColor {
        switch tone {
        case .neutral: colors.textSecondary
        case .info: colors.actionPrimary
        case .success: colors.feedbackSuccess
        case .warning: colors.feedbackWarning
        case .error: colors.feedbackError
        }
    }

    static func resolve(tone: TKTag.Tone, style: TKTag.Style, colors: ColorTokens) -> TKTagColors {
        let color = toneColor(tone, colors: colors)
        switch style {
        case .solid:
            return TKTagColors(background: color, foreground: AdaptiveColor(.white))
        case .soft:
            // Figma's "Inverted": a pale tint in light mode, the raised grey surface in dark mode.
            let tint = AdaptiveColor(light: color.light.mixed(with: .white, by: 0.9), dark: colors.actionNeutral.dark)
            return TKTagColors(background: tint, foreground: color)
        case .outline:
            return TKTagColors(foreground: color, hasBorder: true)
        case .plain:
            return TKTagColors(foreground: color)
        }
    }
}
