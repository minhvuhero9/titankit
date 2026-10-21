import SwiftUI

/// Figma "Radio": a 24 pt ring with a 14 pt dot when selected.
///
///     TKRadioGroup(selection: $level, options: [
///         TKOption(.beginner, title: "Mới bắt đầu"),
///         TKOption(.advanced, title: "Nâng cao"),
///     ])
public struct TKRadio: View {
    private let label: Text
    private let isSelected: Bool
    private let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(_ label: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) {
        self.init(label: Text(label), isSelected: isSelected, action: action)
    }

    public init(label: Text, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                TKRadioMark(isSelected: isSelected, tint: theme.colors.actionPrimary)
                label
                    .tkTextStyle(.label)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// The ring on its own, also used inside TKDropdown rows.
struct TKRadioMark: View {
    let isSelected: Bool
    let tint: AdaptiveColor
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Circle().strokeBorder(tint.color, lineWidth: size / 8)
            if isSelected {
                Circle().fill(tint.color).frame(width: size * 7 / 12, height: size * 7 / 12)
            }
        }
        .frame(width: size, height: size)
    }
}

/// One choice in a radio group, chip group or dropdown.
public struct TKOption<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: Text
    public let icon: Image?

    public var id: Value { value }

    public init(_ value: Value, title: LocalizedStringKey, icon: Image? = nil) {
        self.init(value, title: Text(title), icon: icon)
    }

    public init(_ value: Value, title: Text, icon: Image? = nil) {
        self.value = value
        self.title = title
        self.icon = icon
    }
}

/// A vertical list of TKRadio where exactly one option is selected.
public struct TKRadioGroup<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [TKOption<Value>]

    public init(selection: Binding<Value>, options: [TKOption<Value>]) {
        _selection = selection
        self.options = options
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(options) { option in
                TKRadio(label: option.title, isSelected: option.value == selection) {
                    selection = option.value
                }
            }
        }
    }
}
