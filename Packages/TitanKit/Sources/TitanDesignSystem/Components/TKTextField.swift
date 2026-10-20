import SwiftUI
import TitanLocalization

/// Result of validating a field. The message shows under the field.
public enum TKFieldStatus: Equatable, Sendable {
    case normal
    case error(String)
    case success(String)

    var message: String? {
        switch self {
        case .normal: nil
        case let .error(message), let .success(message): message
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

/// Text input with a label, optional icon and a status message. States follow the Input Form page
/// of the base Figma template: default, focused, filled, error, success, disabled.
///
///     TKTextField("Email", text: $email, prompt: "john@domain.com",
///                 icon: Image(systemName: "envelope"), status: vm.emailStatus)
///     TKTextField("Mật khẩu", text: $password, icon: Image(systemName: "lock"), kind: .secure)
public struct TKTextField: View {
    public enum Kind: Sendable {
        case text
        /// Hidden characters with a show/hide button.
        case secure
        /// Grows to several lines.
        case multiline
    }

    private let label: LocalizedStringKey?
    @Binding private var text: String
    private let prompt: LocalizedStringKey?
    private let icon: Image?
    private let status: TKFieldStatus
    private let kind: Kind
    private let size: TKButton.Size

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.locale) private var locale
    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    /// - Parameter size: field height, matching TKButton sizes so a form lines up.
    public init(
        _ label: LocalizedStringKey? = nil,
        text: Binding<String>,
        prompt: LocalizedStringKey? = nil,
        icon: Image? = nil,
        status: TKFieldStatus = .normal,
        kind: Kind = .text,
        size: TKButton.Size = .large
    ) {
        self.label = label
        _text = text
        self.prompt = prompt
        self.icon = icon
        self.status = status
        self.kind = kind
        self.size = size
    }

    public var body: some View {
        let look = TKFieldAppearance.resolve(status: status, isFocused: isFocused, isEnabled: isEnabled, colors: theme.colors)
        let shape = RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)

        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let label {
                Text(label)
                    .tkTextStyle(.label)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }

            HStack(alignment: kind == .multiline ? .top : .center, spacing: Spacing.sm) {
                icon?
                    .resizable().scaledToFit().frame(width: 20, height: 20)
                    .foregroundStyle(iconColor.color)
                field
                    .tkTextStyle(.callout)
                    .foregroundStyle((isEnabled ? theme.colors.textPrimary : theme.colors.textDisabled).color)
                    .tint(theme.colors.actionPrimary.color)
                    .focused($isFocused)
                if kind == .secure {
                    Button { isRevealed.toggle() } label: {
                        Image(systemName: isRevealed ? "eye" : "eye.slash")
                            .frame(width: 20, height: 20)
                    }
                    .foregroundStyle(iconColor.color)
                    .accessibilityLabel(KitStrings.string(isRevealed ? KitStrings.hidePassword : KitStrings.showPassword, locale: locale))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, kind == .multiline ? 20 : 0)
            .frame(minHeight: kind == .multiline ? size.height * 2 : size.height, alignment: kind == .multiline ? .top : .center)
            .background(look.background.color, in: shape)
            .overlay {
                if let border = look.border { shape.strokeBorder(border.color, lineWidth: 2) }
            }
            .contentShape(shape)
            .onTapGesture { isFocused = true }

            if let message = status.message, let tint = look.messageTint {
                TKFieldMessage(message: message, isError: status.isError, tint: tint)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .animation(.easeOut(duration: 0.15), value: status)
    }

    @ViewBuilder
    private var field: some View {
        let promptText = prompt.map { Text($0).foregroundColor(theme.colors.textDisabled.color) }
        switch kind {
        case .text:
            TextField(label ?? "", text: $text, prompt: promptText)
        case .secure:
            if isRevealed {
                TextField(label ?? "", text: $text, prompt: promptText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(label ?? "", text: $text, prompt: promptText)
            }
        case .multiline:
            TextField(label ?? "", text: $text, prompt: promptText, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    private var iconColor: AdaptiveColor {
        if !isEnabled { return theme.colors.textDisabled }
        if isFocused { return theme.colors.actionPrimary }
        return text.isEmpty ? theme.colors.textDisabled : theme.colors.textPrimary
    }
}

/// Background and border of a field for one state. Kept apart from the view so it can be tested.
struct TKFieldAppearance: Equatable {
    var background: AdaptiveColor
    var border: AdaptiveColor?
    var messageTint: AdaptiveColor?

    static func resolve(status: TKFieldStatus, isFocused: Bool, isEnabled: Bool, colors: ColorTokens) -> TKFieldAppearance {
        guard isEnabled else { return TKFieldAppearance(background: colors.actionDisabled) }
        switch status {
        case .error:
            return TKFieldAppearance(background: colors.surfaceBackground, border: colors.feedbackError, messageTint: colors.feedbackError)
        case .success:
            return TKFieldAppearance(background: colors.surfaceBackground, border: colors.feedbackSuccess, messageTint: colors.feedbackSuccess)
        case .normal:
            if isFocused {
                let tint = colors.actionPrimary
                return TKFieldAppearance(
                    background: AdaptiveColor(light: tint.light.opacity(0.08), dark: tint.dark.opacity(0.16)),
                    border: tint
                )
            }
            return TKFieldAppearance(background: colors.surfaceInput)
        }
    }
}

/// The coloured note under a field: "Email không hợp lệ".
private struct TKFieldMessage: View {
    let message: String
    let isError: Bool
    let tint: AdaptiveColor
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12))
            Text(message)
                .tkTextStyle(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(tint.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 10)
        .background(
            AdaptiveColor(light: tint.light.opacity(0.08), dark: tint.dark.opacity(0.16)).color,
            in: RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
        )
        .transition(.opacity)
    }
}
