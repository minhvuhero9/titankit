import SwiftUI

// Checkbox and switch are ToggleStyles, so they keep SwiftUI's Toggle behaviour and accessibility:
//
//     Toggle("Nhớ đăng nhập", isOn: $remember).toggleStyle(.tkCheckbox)
//     Toggle("Âm thanh", isOn: $sound).toggleStyle(.tkSwitch)
//     Toggle("Âm thanh", isOn: $sound).toggleStyle(.tkSwitch(.line))

/// Figma "Checkbox": a 24 pt rounded square, outlined when off and filled with a tick when on.
public struct TKCheckboxToggleStyle: ToggleStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: Spacing.md) {
                TKCheckboxMark(isOn: configuration.isOn, tint: theme.colors.actionPrimary)
                configuration.label
                    .tkTextStyle(.label)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: configuration.isOn)
    }
}

/// The square on its own, also used inside TKDropdown rows.
struct TKCheckboxMark: View {
    let isOn: Bool
    let tint: AdaptiveColor
    var size: CGFloat = 24

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size / 4, style: .continuous)
        ZStack {
            if isOn {
                shape.fill(tint.color)
                TKCheckmark()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: size / 9, lineCap: .round, lineJoin: .round))
                    .frame(width: size / 2, height: size * 3 / 8)
            } else {
                shape.strokeBorder(tint.color, lineWidth: size / 8)
            }
        }
        .frame(width: size, height: size)
    }
}

struct TKCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Figma "Toggle". `.standard` is the iOS-like pill with the knob inside;
/// `.line` is a thin track with a larger knob that overhangs it.
public struct TKSwitchToggleStyle: ToggleStyle {
    public enum Variant: Sendable {
        case standard
        case line
    }

    private let variant: Variant
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(_ variant: Variant = .standard) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        let look = TKSwitchColors.resolve(variant, isOn: configuration.isOn, colors: theme.colors)
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: Spacing.md) {
                configuration.label
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                track(look: look, isOn: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isOn)
    }

    @ViewBuilder
    private func track(look: TKSwitchColors, isOn: Bool) -> some View {
        switch variant {
        case .standard:
            Capsule()
                .fill(look.track.color)
                .frame(width: 44, height: 24)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle().fill(look.knob.color).frame(width: 20, height: 20).padding(2)
                }
        case .line:
            Capsule()
                .fill(look.track.color)
                .frame(width: 48, height: 18)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(look.knob.color)
                        .overlay { if let ring = look.knobBorder { Circle().strokeBorder(ring.color, lineWidth: 2) } }
                        .frame(width: 24, height: 24)
                }
                .frame(height: 24)
        }
    }
}

/// Colours of a switch for one state. Kept apart from the view so it can be tested.
struct TKSwitchColors: Equatable {
    var track: AdaptiveColor
    var knob: AdaptiveColor
    var knobBorder: AdaptiveColor?

    static func resolve(_ variant: TKSwitchToggleStyle.Variant, isOn: Bool, colors: ColorTokens) -> TKSwitchColors {
        let white = AdaptiveColor(.white)
        switch (variant, isOn) {
        case (.standard, true):
            return TKSwitchColors(track: colors.actionPrimary, knob: white)
        case (.standard, false):
            return TKSwitchColors(track: colors.border, knob: white)
        case (.line, true):
            return TKSwitchColors(track: colors.actionPrimary, knob: white, knobBorder: colors.actionPrimary)
        case (.line, false):
            return TKSwitchColors(track: colors.border, knob: AdaptiveColor(light: colors.textDisabled.light, dark: .white))
        }
    }
}

public extension ToggleStyle where Self == TKCheckboxToggleStyle {
    static var tkCheckbox: TKCheckboxToggleStyle { TKCheckboxToggleStyle() }
}

public extension ToggleStyle where Self == TKSwitchToggleStyle {
    static var tkSwitch: TKSwitchToggleStyle { TKSwitchToggleStyle() }
    static func tkSwitch(_ variant: TKSwitchToggleStyle.Variant) -> TKSwitchToggleStyle { TKSwitchToggleStyle(variant) }
}
