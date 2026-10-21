import SwiftUI
import TitanIcons

/// Figma "Dropdown": a field that opens a list of options right below it.
/// Single choice shows radio marks, multiple choice shows checkboxes.
///
///     TKDropdown("Trình độ", selection: $level, options: levels, prompt: "Chọn trình độ")
///     TKDropdown("Chủ đề", selection: $topics, options: topics)        // Set<Value>
///
/// The list opens in the layout and pushes the views below it down, so it is never hidden
/// behind a sibling or clipped by a scroll view.
public struct TKDropdown<Value: Hashable>: View {
    private enum Mode {
        case single(Binding<Value?>)
        case multiple(Binding<Set<Value>>)
    }

    private let label: Text?
    private let prompt: Text?
    private let options: [TKOption<Value>]
    private let mode: Mode

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @State private var isOpen = false

    public init(
        _ label: LocalizedStringKey? = nil,
        selection: Binding<Value?>,
        options: [TKOption<Value>],
        prompt: LocalizedStringKey? = nil
    ) {
        self.label = label.map { Text($0) }
        self.prompt = prompt.map { Text($0) }
        self.options = options
        mode = .single(selection)
    }

    public init(
        _ label: LocalizedStringKey? = nil,
        selection: Binding<Set<Value>>,
        options: [TKOption<Value>],
        prompt: LocalizedStringKey? = nil
    ) {
        self.label = label.map { Text($0) }
        self.prompt = prompt.map { Text($0) }
        self.options = options
        mode = .multiple(selection)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let label {
                label
                    .tkTextStyle(.label)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
            trigger
            if isOpen {
                menu.transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: isOpen)
    }

    private var trigger: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
        return Button { isOpen.toggle() } label: {
            HStack(spacing: Spacing.sm) {
                summary
                    .tkTextStyle(.callout)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(tk: .arrowDown2)
                    .resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .foregroundStyle((isOpen ? theme.colors.actionPrimary : theme.colors.textPrimary).color)
            }
            .padding(.horizontal, 20)
            .frame(height: TKButton.Size.large.height)
            .background(shape.fill((isEnabled ? theme.colors.surfaceInput : theme.colors.surfaceDisabled).color))
            .overlay { if isOpen { shape.strokeBorder(theme.colors.actionPrimary.color, lineWidth: 2) } }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }

    private var summary: Text {
        let titles = options.filter { isSelected($0.value) }.map(\.title)
        guard let first = titles.first else {
            return (prompt ?? Text(verbatim: "")).foregroundColor(theme.colors.textDisabled.color)
        }
        let joined = titles.dropFirst().reduce(first) { $0 + Text(verbatim: ", ") + $1 }
        return joined.foregroundColor((isEnabled ? theme.colors.textPrimary : theme.colors.textDisabled).color)
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                if index > 0 { Divider().overlay(theme.colors.border.color) }
                Button { select(option.value) } label: {
                    HStack(spacing: Spacing.sm) {
                        mark(for: option)
                        option.title
                            .tkTextStyle(.label)
                            .foregroundStyle(theme.colors.textPrimary.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected(option.value) ? .isSelected : [])
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 28))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AdaptiveColor(light: theme.colors.surfaceBackground.light, dark: theme.colors.actionSecondary.dark).color,
            in: RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
        )
        // Figma: 0, 20, blur 100 at 8 %.
        .tkElevation(Elevation(color: RGBA(hex: 0x04060F, alpha: 0.08), radius: 50, y: 20))
    }

    @ViewBuilder
    private func mark(for option: TKOption<Value>) -> some View {
        if let icon = option.icon {
            icon.resizable().scaledToFit().frame(width: 24, height: 24)
                .foregroundStyle(theme.colors.textPrimary.color)
        } else {
            switch mode {
            case .single:
                TKRadioMark(isSelected: isSelected(option.value), tint: theme.colors.actionPrimary, size: 20)
            case .multiple:
                TKCheckboxMark(isOn: isSelected(option.value), tint: theme.colors.actionPrimary, size: 20)
            }
        }
    }

    private func isSelected(_ value: Value) -> Bool {
        switch mode {
        case let .single(selection): selection.wrappedValue == value
        case let .multiple(selection): selection.wrappedValue.contains(value)
        }
    }

    private func select(_ value: Value) {
        switch mode {
        case let .single(selection):
            selection.wrappedValue = value
            isOpen = false
        case let .multiple(selection):
            selection.wrappedValue = TKSelection.toggling(value, in: selection.wrappedValue)
        }
    }
}

/// Selection rules shared by dropdowns and chip groups. Kept apart so they can be tested.
enum TKSelection {
    static func toggling<Value: Hashable>(_ value: Value, in set: Set<Value>) -> Set<Value> {
        var result = set
        if result.contains(value) { result.remove(value) } else { result.insert(value) }
        return result
    }
}
