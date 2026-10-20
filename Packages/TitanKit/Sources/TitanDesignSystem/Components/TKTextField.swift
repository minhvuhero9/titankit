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

    private let label: Text?
    @Binding private var text: String
    private let prompt: Text?
    private let icon: Image?
    private let status: TKFieldStatus
    private let kind: Kind
    private let size: TKButton.Size

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.locale) private var locale
    @Environment(\.tkFieldStyle) private var fieldStyle
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
        self.init(label: label.map { Text($0) }, text: text, prompt: prompt.map { Text($0) },
                  icon: icon, status: status, kind: kind, size: size)
    }

    /// Takes ready Texts, e.g. kit strings already looked up for the current language.
    public init(
        label: Text?,
        text: Binding<String>,
        prompt: Text? = nil,
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
                label
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
            .padding(.horizontal, fieldStyle == .filled ? 20 : 0)
            .padding(.vertical, kind == .multiline ? 20 : 0)
            .frame(minHeight: kind == .multiline ? size.height * 2 : fieldHeight, alignment: kind == .multiline ? .top : .center)
            .background {
                if fieldStyle == .filled { shape.fill(look.background.color) }
            }
            .overlay {
                if fieldStyle == .filled {
                    if let border = look.border { shape.strokeBorder(border.color, lineWidth: 2) }
                } else {
                    Rectangle()
                        .fill((look.border ?? theme.colors.border).color)
                        .frame(height: look.border == nil ? 1 : 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .contentShape(Rectangle())
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
        let promptText = prompt?.foregroundColor(theme.colors.textDisabled.color)
        let fieldLabel = label ?? Text(verbatim: "")
        switch kind {
        case .text:
            TextField(text: $text, prompt: promptText) { fieldLabel }
        case .secure:
            if isRevealed {
                TextField(text: $text, prompt: promptText) { fieldLabel }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField(text: $text, prompt: promptText) { fieldLabel }
            }
        case .multiline:
            TextField(text: $text, prompt: promptText, axis: .vertical) { fieldLabel }
                .lineLimit(3...8)
        }
    }

    /// Underlined fields have no box, so they sit tighter.
    private var fieldHeight: CGFloat {
        fieldStyle == .filled ? size.height : size.height - Spacing.md
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
        guard isEnabled else { return TKFieldAppearance(background: colors.surfaceDisabled) }
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

/// How every TKTextField below draws itself. The Figma template uses `.filled` on its component page
/// and `.underlined` on the sign-in screens.
public enum TKFieldStyle: Sendable {
    case filled
    case underlined
}

private struct TKFieldStyleKey: EnvironmentKey {
    static let defaultValue = TKFieldStyle.filled
}

public extension EnvironmentValues {
    var tkFieldStyle: TKFieldStyle {
        get { self[TKFieldStyleKey.self] }
        set { self[TKFieldStyleKey.self] = newValue }
    }
}

public extension View {
    func tkFieldStyle(_ style: TKFieldStyle) -> some View {
        environment(\.tkFieldStyle, style)
    }
}
