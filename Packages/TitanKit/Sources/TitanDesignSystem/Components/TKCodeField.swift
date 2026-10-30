import SwiftUI

/// A one-time code typed into boxes, one digit each, with the number pad and code autofill.
/// The box being filled is highlighted like a focused field. Figma "enter OTP code".
///
///     TKCodeField(code: $viewModel.code, length: 4, isError: viewModel.isCodeWrong)
public struct TKCodeField: View {
    @Binding private var code: String
    private let length: Int
    private let isError: Bool

    @FocusState private var isFocused: Bool
    @Environment(\.theme) private var theme

    public init(code: Binding<String>, length: Int = 4, isError: Bool = false) {
        _code = code
        self.length = max(1, length)
        self.isError = isError
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(0..<length, id: \.self) { index in
                box(at: index)
            }
        }
        .accessibilityHidden(true)
        // The real field sits under the boxes: it gets the keyboard, autofill and VoiceOver.
        .background {
            TextField(text: $code) { Text(verbatim: "") }
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .opacity(0.02)
                .accessibilityValue(Text(verbatim: code))
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onAppear { isFocused = true }
        .onChange(of: code) { newValue in
            let cleaned = Self.sanitize(newValue, length: length)
            if cleaned != newValue { code = cleaned }
        }
        .animation(.easeOut(duration: 0.15), value: code)
    }

    private func box(at index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
        let isActive = isFocused && Self.activeIndex(count: code.count, length: length) == index
        let look = TKFieldAppearance.resolve(
            status: isError ? .error("") : .normal, isFocused: isActive, isEnabled: true, colors: theme.colors
        )
        return Text(verbatim: Self.digit(in: code, at: index))
            .tkTextStyle(.title2)
            .foregroundStyle(theme.colors.textPrimary.color)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(shape.fill(look.background.color))
            .overlay {
                if let border = look.border { shape.strokeBorder(border.color, lineWidth: 2) }
            }
    }

    /// Digits only, at most `length` of them, so pasting "Code: 1234" still works.
    nonisolated static func sanitize(_ text: String, length: Int) -> String {
        String(text.filter(\.isASCIIDigit).prefix(length))
    }

    /// The box the next digit goes into; the last box once the code is complete.
    nonisolated static func activeIndex(count: Int, length: Int) -> Int {
        min(count, length - 1)
    }

    nonisolated static func digit(in code: String, at index: Int) -> String {
        guard index < code.count else { return "" }
        return String(code[code.index(code.startIndex, offsetBy: index)])
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
