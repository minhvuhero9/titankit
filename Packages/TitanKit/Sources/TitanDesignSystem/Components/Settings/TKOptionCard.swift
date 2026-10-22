import SwiftUI
import TitanIcons

/// Figma "Select Country", "Linked Accounts" and "Payment Methods": an outlined card with a
/// picture, a title, an optional detail line and something at the end.
/// While selected it gets a brand border and, unless `trailing` is given, a brand tick.
///
///     TKOptionCard("Việt Nam", isSelected: country == .vn) {
///         Image("flag.vn").resizable().frame(width: 60, height: 45)
///     } action: { country = .vn }
///
///     TKOptionCard("Google", detail: "an@gmail.com") {
///         Image("google")
///     } trailing: {
///         Text("Đã liên kết")
///     } action: { unlink(.google) }
public struct TKOptionCard<Leading: View, Trailing: View>: View {
    private let title: Text
    private let detail: Text?
    private let isSelected: Bool
    private let leading: Leading
    private let trailing: Trailing
    private let action: () -> Void

    @Environment(\.theme) private var theme

    public init(
        _ title: String,
        detail: String? = nil,
        isSelected: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        action: @escaping () -> Void
    ) {
        self.init(title: Text(title), detail: detail.map { Text($0) }, isSelected: isSelected,
                  leading: leading, trailing: trailing, action: action)
    }

    public init(
        title: Text,
        detail: Text? = nil,
        isSelected: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.isSelected = isSelected
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                leading
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    title
                        .font(theme.typography.font(size: 18, weight: .semibold, relativeTo: .headline))
                        .foregroundStyle(theme.colors.textPrimary.color)
                    detail?
                        .font(theme.typography.font(size: 14, weight: .medium, relativeTo: .callout))
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                if Trailing.self == EmptyView.self {
                    Image(tk: TKSymbol.check)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(theme.colors.actionPrimary.color)
                        .opacity(isSelected ? 1 : 0)
                        .accessibilityHidden(true)
                } else {
                    trailing
                        .font(theme.typography.font(size: 16, weight: .semibold, relativeTo: .callout))
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
            .tkOutlinedCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

public extension TKOptionCard where Trailing == EmptyView {
    init(
        _ title: String,
        detail: String? = nil,
        isSelected: Bool = false,
        @ViewBuilder leading: () -> Leading,
        action: @escaping () -> Void
    ) {
        self.init(title, detail: detail, isSelected: isSelected, leading: leading, trailing: { EmptyView() }, action: action)
    }

    init(
        title: Text,
        detail: Text? = nil,
        isSelected: Bool = false,
        @ViewBuilder leading: () -> Leading,
        action: @escaping () -> Void
    ) {
        self.init(title: title, detail: detail, isSelected: isSelected, leading: leading, trailing: { EmptyView() }, action: action)
    }
}
