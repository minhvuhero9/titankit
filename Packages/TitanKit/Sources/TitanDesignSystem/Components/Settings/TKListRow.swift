import SwiftUI

/// Figma "Account List": a leading view (usually an avatar), a bold title, a grey subtitle
/// and anything at the end, e.g. a button, call icons or a score.
///
///     TKListRow("Anna", subtitle: "anna@mail.com") {
///         TKAvatar(name: "Anna", size: 60)
///     } trailing: {
///         TKChip("Xem", isSelected: true, size: .small) { open(anna) }
///     }
public struct TKListRow<Leading: View, Trailing: View>: View {
    private let title: Text
    private let subtitle: Text?
    private let leading: Leading
    private let trailing: Trailing

    @Environment(\.theme) private var theme

    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title: Text(title), subtitle: subtitle.map { Text($0) }, leading: leading, trailing: trailing)
    }

    public init(
        title: Text,
        subtitle: Text? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: 20) {
                leading
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    title
                        .font(theme.typography.font(size: 18, weight: .bold, relativeTo: .headline))
                        .foregroundStyle(theme.colors.textPrimary.color)
                    subtitle?
                        .font(theme.typography.font(size: 14, weight: .medium, relativeTo: .callout))
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            trailing
        }
    }
}

public extension TKListRow where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, @ViewBuilder leading: () -> Leading) {
        self.init(title, subtitle: subtitle, leading: leading) { EmptyView() }
    }

    init(title: Text, subtitle: Text? = nil, @ViewBuilder leading: () -> Leading) {
        self.init(title: title, subtitle: subtitle, leading: leading) { EmptyView() }
    }
}
