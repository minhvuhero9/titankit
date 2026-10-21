import SwiftUI
import TitanIcons
import TitanLocalization

/// Figma "Search": a filled field with a search icon and a clear button once there is text.
/// While focused it takes a brand tint and border, like TKTextField.
///
///     TKSearchField(text: $query) { vm.search(query) }
public struct TKSearchField: View {
    @Binding private var text: String
    private let prompt: Text?
    private let onSubmit: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale
    @FocusState private var isFocused: Bool

    /// - Parameter prompt: placeholder; the kit's "Tìm kiếm" / "Search" when nil.
    public init(text: Binding<String>, prompt: LocalizedStringKey? = nil, onSubmit: @escaping () -> Void = {}) {
        _text = text
        self.prompt = prompt.map { Text($0) }
        self.onSubmit = onSubmit
    }

    public var body: some View {
        let look = TKFieldAppearance.resolve(status: .normal, isFocused: isFocused, isEnabled: true, colors: theme.colors)
        let shape = RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
        HStack(spacing: Spacing.sm) {
            Image(tk: TKIcon.search)
                .resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle((isFocused || !text.isEmpty ? theme.colors.textPrimary : theme.colors.textDisabled).color)
            TextField(text: $text, prompt: placeholder.foregroundColor(theme.colors.textDisabled.color)) { placeholder }
                .font(theme.typography.font(size: 18, weight: .regular, relativeTo: .body))
                .foregroundStyle(theme.colors.textPrimary.color)
                .tint(theme.colors.actionPrimary.color)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit(onSubmit)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(tk: TKSymbol.cancel)
                        .resizable().scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(theme.colors.textPrimary.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text.kit(KitStrings.clear, locale: locale))
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: TKButton.Size.large.height)
        .background(look.background.color, in: shape)
        .overlay { if let border = look.border { shape.strokeBorder(border.color, lineWidth: 1) } }
        .contentShape(shape)
        .onTapGesture { isFocused = true }
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .animation(.easeOut(duration: 0.15), value: text.isEmpty)
    }

    private var placeholder: Text {
        prompt ?? Text.kit(KitStrings.search, locale: locale)
    }
}
