import SwiftUI

/// The kit's button. Styles, sizes and shapes follow the Button page of the base Figma template.
///
///     TKButton("Tiếp tục", isLoading: vm.isSaving) { Task { await vm.save() } }
///     TKButton("Bỏ qua", style: .light, size: .medium) { skip() }
public struct TKButton: View {
    public enum Style: String, CaseIterable, Sendable {
        /// Filled with the brand colour. The main action on a screen.
        case primary
        /// Soft brand tint with brand text.
        case light
        /// Dark in both modes.
        case neutral
        /// Brand outline, no fill.
        case outline
        /// Card colour with a thin grey border, e.g. "Continue with Apple".
        case bordered
        /// Primary with a soft shadow.
        case elevated
        /// Primary with a darker bottom edge that sinks when pressed.
        case threeD
    }

    public enum Size: String, CaseIterable, Sendable {
        case large, medium, small, extraSmall

        public var height: CGFloat {
            switch self {
            case .large: 65
            case .medium: 58
            case .small: 50
            case .extraSmall: 43
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .large: 18
            case .medium: 16
            case .small: 14
            case .extraSmall: 12
            }
        }

        var iconSize: CGFloat { fontSize + 2 }

        var horizontalPadding: CGFloat {
            switch self {
            case .large: Spacing.lg
            case .medium: 20
            case .small: Spacing.md
            case .extraSmall: Spacing.sm
            }
        }
    }

    public enum Shape: String, CaseIterable, Sendable {
        /// Corner radius from the theme (`radius.md`).
        case rounded
        case pill
    }

    private let title: Text
    private let style: Style
    private let size: Size
    private let shape: Shape?
    private let fullWidth: Bool
    private let leadingIcon: Image?
    private let trailingIcon: Image?
    private let isLoading: Bool
    private let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.tkButtonShape) private var defaultShape

    /// - Parameters:
    ///   - shape: nil uses the shape set with `.tkButtonShape(_:)`, `.rounded` by default.
    ///   - isLoading: shows a spinner and ignores taps.
    public init(
        _ title: LocalizedStringKey,
        style: Style = .primary,
        size: Size = .large,
        shape: Shape? = nil,
        fullWidth: Bool = true,
        leadingIcon: Image? = nil,
        trailingIcon: Image? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(Text(title), style: style, size: size, shape: shape, fullWidth: fullWidth,
                  leadingIcon: leadingIcon, trailingIcon: trailingIcon, isLoading: isLoading, action: action)
    }

    /// Takes a ready Text, e.g. a kit string already looked up for the current language.
    public init(
        _ title: Text,
        style: Style = .primary,
        size: Size = .large,
        shape: Shape? = nil,
        fullWidth: Bool = true,
        leadingIcon: Image? = nil,
        trailingIcon: Image? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.shape = shape
        self.fullWidth = fullWidth
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(TKButtonChrome(
            style: style,
            height: size.height,
            radius: (shape ?? defaultShape) == .pill ? Radius.full : theme.radius.md,
            fullWidth: fullWidth,
            horizontalPadding: size.horizontalPadding
        ))
        .disabled(isLoading)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var label: some View {
        if isLoading {
            ProgressView()
        } else {
            HStack(spacing: Spacing.xs) {
                leadingIcon?.resizable().scaledToFit().frame(width: size.iconSize, height: size.iconSize)
                title
                    .font(theme.typography.font(size: size.fontSize, weight: .bold, relativeTo: .headline))
                    .tracking(0.2)
                    // Two lines at large text sizes rather than "Continue wit…"; the button
                    // grows past its height (a minimum) to fit them.
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                trailingIcon?.resizable().scaledToFit().frame(width: size.iconSize, height: size.iconSize)
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

/// Square or round button with only an icon, e.g. "+" or "close". Same styles as TKButton.
public struct TKIconButton: View {
    private let icon: Image
    private let accessibilityLabel: LocalizedStringKey
    private let style: TKButton.Style
    private let size: TKButton.Size
    private let shape: TKButton.Shape?
    private let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.tkButtonShape) private var defaultShape

    /// - Parameter accessibilityLabel: read by VoiceOver, since there is no visible text.
    public init(
        _ icon: Image,
        accessibilityLabel: LocalizedStringKey,
        style: TKButton.Style = .primary,
        size: TKButton.Size = .small,
        shape: TKButton.Shape? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.style = style
        self.size = size
        self.shape = shape
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            icon.resizable().scaledToFit().frame(width: size.iconSize, height: size.iconSize)
        }
        .buttonStyle(TKButtonChrome(
            style: style,
            height: size.height,
            radius: (shape ?? defaultShape) == .pill ? Radius.full : theme.radius.md,
            fullWidth: false,
            horizontalPadding: 0,
            width: size.height
        ))
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

/// Colours of one button style, worked out from the theme. Kept apart from the view so it can be tested.
struct TKButtonColors: Equatable {
    var background: AdaptiveColor?
    var foreground: AdaptiveColor
    var border: AdaptiveColor?
    /// Bottom edge of the 3D style.
    var edge: AdaptiveColor?
    var elevation: Elevation

    static let edgeHeight: CGFloat = 4

    static func resolve(_ style: TKButton.Style, colors: ColorTokens, isEnabled: Bool) -> TKButtonColors {
        guard isEnabled else {
            if style == .outline {
                return TKButtonColors(foreground: colors.actionOnDisabled, border: colors.actionDisabled, elevation: .flat)
            }
            return TKButtonColors(background: colors.actionDisabled, foreground: colors.actionOnDisabled, elevation: .flat)
        }
        switch style {
        case .primary:
            return TKButtonColors(background: colors.actionPrimary, foreground: colors.actionOnPrimary, elevation: .flat)
        case .light:
            return TKButtonColors(background: colors.actionSecondary, foreground: colors.actionOnSecondary, elevation: .flat)
        case .neutral:
            return TKButtonColors(background: colors.actionNeutral, foreground: colors.actionOnNeutral, elevation: .flat)
        case .outline:
            return TKButtonColors(foreground: colors.actionPrimary, border: colors.actionPrimary, elevation: .flat)
        case .bordered:
            return TKButtonColors(background: colors.surfaceCard, foreground: colors.textPrimary, border: colors.border, elevation: .flat)
        case .elevated:
            let glow = Elevation(color: colors.actionPrimary.light.opacity(0.25), radius: 12, y: 8)
            return TKButtonColors(background: colors.actionPrimary, foreground: colors.actionOnPrimary, elevation: glow)
        case .threeD:
            return TKButtonColors(
                background: colors.actionPrimary,
                foreground: colors.actionOnPrimary,
                edge: colors.actionPrimaryPressed,
                elevation: .flat
            )
        }
    }
}

/// Draws the background, border, edge and pressed state shared by TKButton and TKIconButton.
private struct TKButtonChrome: ButtonStyle {
    let style: TKButton.Style
    let height: CGFloat
    let radius: CGFloat
    let fullWidth: Bool
    let horizontalPadding: CGFloat
    var width: CGFloat?

    func makeBody(configuration: Configuration) -> some View {
        ChromeBody(configuration: configuration, chrome: self)
    }

    private struct ChromeBody: View {
        let configuration: ButtonStyleConfiguration
        let chrome: TKButtonChrome
        @Environment(\.theme) private var theme
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let colors = TKButtonColors.resolve(chrome.style, colors: theme.colors, isEnabled: isEnabled)
            let shape = RoundedRectangle(cornerRadius: chrome.radius, style: .continuous)
            let pressed = configuration.isPressed
            let sink: CGFloat = colors.edge != nil && pressed ? TKButtonColors.edgeHeight : 0

            configuration.label
                .foregroundStyle(colors.foreground.color)
                .tint(colors.foreground.color)
                .padding(.horizontal, chrome.horizontalPadding)
                .frame(width: chrome.width)
                .frame(maxWidth: chrome.fullWidth ? .infinity : nil, minHeight: chrome.height)
                .background {
                    if let background = colors.background { shape.fill(background.color) }
                }
                .overlay {
                    if let border = colors.border { shape.strokeBorder(border.color, lineWidth: 2) }
                }
                .contentShape(shape)
                .opacity(pressed && colors.edge == nil ? 0.8 : 1)
                .offset(y: sink)
                .background(alignment: .bottom) {
                    if let edge = colors.edge {
                        shape.fill(edge.color).offset(y: TKButtonColors.edgeHeight)
                    }
                }
                .padding(.bottom, colors.edge != nil ? TKButtonColors.edgeHeight : 0)
                .tkElevation(colors.elevation)
                .animation(.easeOut(duration: 0.1), value: pressed)
        }
    }
}

private struct TKButtonShapeKey: EnvironmentKey {
    static let defaultValue = TKButton.Shape.rounded
}

public extension EnvironmentValues {
    var tkButtonShape: TKButton.Shape {
        get { self[TKButtonShapeKey.self] }
        set { self[TKButtonShapeKey.self] = newValue }
    }
}

public extension View {
    /// Default shape for every TKButton below, e.g. `.tkButtonShape(.pill)` at the app root.
    func tkButtonShape(_ shape: TKButton.Shape) -> some View {
        environment(\.tkButtonShape, shape)
    }
}
