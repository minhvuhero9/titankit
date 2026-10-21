import SwiftUI
import TitanIcons

/// Figma "Alert": an inline message on a pale tint of its status colour, e.g. under a form.
///
///     TKAlert("Mật khẩu chưa đúng", status: .error)
///     TKAlert(title: Text(KitStrings.text(...)), status: .success)
public struct TKAlert: View {
    public enum Status: String, CaseIterable, Sendable {
        case info, success, warning, error

        var defaultIcon: Image {
            switch self {
            case .info: Image(tk: TKIcon.infoSquare, style: .bold)
            case .success: Image(tk: TKSymbol.checkCircleFill)
            case .warning: Image(tk: TKIcon.dangerTriangle, style: .bold)
            case .error: Image(tk: TKIcon.dangerCircle, style: .bold)
            }
        }
    }

    private let title: Text
    private let status: Status
    private let icon: Image?

    @Environment(\.theme) private var theme

    /// - Parameter icon: nil uses the status's own icon.
    public init(_ title: LocalizedStringKey, status: Status = .info, icon: Image? = nil) {
        self.init(title: Text(title), status: status, icon: icon)
    }

    public init(title: Text, status: Status = .info, icon: Image? = nil) {
        self.title = title
        self.status = status
        self.icon = icon
    }

    public var body: some View {
        let look = TKAlertColors.resolve(status: status, colors: theme.colors)
        HStack(alignment: .top, spacing: Spacing.xs) {
            (icon ?? status.defaultIcon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(.top, 2)
                .accessibilityHidden(true)
            title
                .font(theme.typography.font(size: 14, weight: .regular, relativeTo: .callout))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(look.foreground.color)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(look.background.color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Colours of an alert. Kept apart from the view so it can be tested.
struct TKAlertColors: Equatable {
    var background: AdaptiveColor
    var foreground: AdaptiveColor

    /// Figma tints the background with 8% of the status colour, in both modes.
    static let tintOpacity = 0.08

    static func resolve(status: TKAlert.Status, colors: ColorTokens) -> TKAlertColors {
        let color: AdaptiveColor = switch status {
        // Figma's info alert uses the brand colour, like the info tag.
        case .info: colors.actionPrimary
        case .success: colors.feedbackSuccess
        case .warning: colors.feedbackWarning
        case .error: colors.feedbackError
        }
        let tint = AdaptiveColor(light: color.light.opacity(tintOpacity), dark: color.dark.opacity(tintOpacity))
        return TKAlertColors(background: tint, foreground: color)
    }
}
