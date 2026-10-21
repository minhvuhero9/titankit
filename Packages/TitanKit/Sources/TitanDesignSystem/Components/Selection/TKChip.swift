import SwiftUI

/// Figma "Chips": pill-shaped filters and choices in three sizes.
///
///     TKChip("Tất cả", isSelected: filter == .all) { filter = .all }
///     TKChip("Ngữ pháp", icon: Image(tk: .document), style: .outline, size: .small) { ... }
public struct TKChip: View {
    public enum Style: String, CaseIterable, Sendable {
        /// Brand fill, white text. A selected chip.
        case filled
        /// Brand border and text.
        case outline
        /// Grey border, normal text. An unselected chip.
        case neutral
    }

    public enum Size: String, CaseIterable, Sendable {
        case small, medium, large

        public var height: CGFloat {
            switch self {
            case .small: 34
            case .medium: 42
            case .large: 49
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: 14
            case .medium: 16
            case .large: 18
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: 16
            case .medium: 20
            case .large: 24
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: 14
            case .medium: 16
            case .large: 20
            }
        }
    }

    private let title: Text
    private let icon: Image?
    private let style: Style
    private let size: Size
    private let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ title: LocalizedStringKey,
        icon: Image? = nil,
        style: Style = .neutral,
        size: Size = .medium,
        action: @escaping () -> Void
    ) {
        self.init(title: Text(title), icon: icon, style: style, size: size, action: action)
    }

    /// A choice chip: filled when selected, neutral otherwise.
    public init(
        _ title: LocalizedStringKey,
        icon: Image? = nil,
        isSelected: Bool,
        size: Size = .medium,
        action: @escaping () -> Void
    ) {
        self.init(title: Text(title), icon: icon, style: isSelected ? .filled : .neutral, size: size, action: action)
    }

    public init(title: Text, icon: Image? = nil, style: Style = .neutral, size: Size = .medium, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    public var body: some View {
        let look = TKChipColors.resolve(style, colors: theme.colors)
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                icon?
                    .resizable().scaledToFit()
                    .frame(width: size.iconSize, height: size.iconSize)
                title
                    .font(theme.typography.font(size: size.fontSize, weight: .semibold, relativeTo: .callout))
                    .tracking(0.2)
                    .lineLimit(1)
            }
            .foregroundStyle(look.foreground.color)
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background { if let fill = look.background { Capsule().fill(fill.color) } }
            .overlay { if let border = look.border { Capsule().strokeBorder(border.color, lineWidth: look.borderWidth) } }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityAddTraits(style == .filled ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: style)
    }
}

/// Colours of a chip for one style. Kept apart from the view so it can be tested.
struct TKChipColors: Equatable {
    var background: AdaptiveColor?
    var foreground: AdaptiveColor
    var border: AdaptiveColor?
    var borderWidth: CGFloat = 0

    static func resolve(_ style: TKChip.Style, colors: ColorTokens) -> TKChipColors {
        switch style {
        case .filled:
            TKChipColors(background: colors.actionPrimary, foreground: colors.actionOnPrimary)
        case .outline:
            TKChipColors(foreground: colors.actionPrimary, border: colors.actionPrimary, borderWidth: 1.5)
        case .neutral:
            TKChipColors(foreground: colors.textPrimary, border: colors.border, borderWidth: 1)
        }
    }
}
