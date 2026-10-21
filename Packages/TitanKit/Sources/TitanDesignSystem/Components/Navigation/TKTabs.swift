import SwiftUI

/// Figma "Horizontal Tab": equal-width tabs with an underline that slides to the selected one.
///
///     TKUnderlineTabs(selection: $section, options: [
///         TKOption(.lessons, title: "Bài học"),
///         TKOption(.words, title: "Từ vựng", icon: Image(tk: .document)),
///     ])
public struct TKUnderlineTabs<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [TKOption<Value>]

    @Environment(\.theme) private var theme
    @Namespace private var underline

    public init(selection: Binding<Value>, options: [TKOption<Value>]) {
        _selection = selection
        self.options = options
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                let isSelected = option.value == selection
                let tint = isSelected ? theme.colors.actionPrimary : theme.colors.textDisabled
                Button { selection = option.value } label: {
                    VStack(spacing: Spacing.sm) {
                        HStack(spacing: Spacing.xs) {
                            option.icon?
                                .resizable().scaledToFit()
                                .frame(width: 16, height: 16)
                            option.title
                                .font(theme.typography.font(size: 18, weight: .semibold, relativeTo: .headline))
                                .tracking(0.2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(tint.color)
                        ZStack {
                            Capsule().fill(theme.colors.border.color).frame(height: 2)
                            if isSelected {
                                Capsule()
                                    .fill(theme.colors.actionPrimary.color)
                                    .frame(height: 4)
                                    .matchedGeometryEffect(id: "underline", in: underline)
                            }
                        }
                        .frame(height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selection)
    }
}

/// Figma "Paging Horizontal Tab": a grey track where the selected segment is filled with the brand colour.
///
///     TKSegmentedTabs(selection: $period, options: [TKOption(.week, title: "Tuần"), TKOption(.month, title: "Tháng")])
public struct TKSegmentedTabs<Value: Hashable>: View {
    @Binding private var selection: Value
    private let options: [TKOption<Value>]

    @Environment(\.theme) private var theme
    @Namespace private var thumb

    public init(selection: Binding<Value>, options: [TKOption<Value>]) {
        _selection = selection
        self.options = options
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
        HStack(spacing: 0) {
            ForEach(options) { option in
                let isSelected = option.value == selection
                Button { selection = option.value } label: {
                    HStack(spacing: Spacing.xs) {
                        option.icon?
                            .resizable().scaledToFit()
                            .frame(width: 16, height: 16)
                        option.title
                            .font(theme.typography.font(size: 16, weight: .semibold, relativeTo: .body))
                            .tracking(0.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle((isSelected ? theme.colors.actionOnPrimary : theme.colors.textPrimary).color)
                    .padding(.horizontal, Spacing.sm)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background {
                        if isSelected {
                            shape.fill(theme.colors.actionPrimary.color)
                                .matchedGeometryEffect(id: "thumb", in: thumb)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .background(theme.colors.surfaceInput.color, in: shape)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selection)
    }
}
