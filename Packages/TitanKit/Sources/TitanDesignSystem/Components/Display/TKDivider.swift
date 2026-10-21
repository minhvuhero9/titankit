import SwiftUI

/// Figma "Divider": a 1 pt line in the theme's border colour, with an optional label in the middle.
///
///     TKDivider()
///     TKDivider("hoặc tiếp tục với")
public struct TKDivider: View {
    private let label: Text?
    @Environment(\.theme) private var theme

    public init() {
        label = nil
    }

    public init(_ label: LocalizedStringKey) {
        self.label = Text(label)
    }

    public init(label: Text) {
        self.label = label
    }

    public var body: some View {
        if let label {
            HStack(spacing: Spacing.md) {
                line
                label
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .layoutPriority(1)
                line
            }
        } else {
            line
        }
    }

    private var line: some View {
        Rectangle()
            .fill(theme.colors.border.color)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}
