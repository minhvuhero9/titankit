import SwiftUI
import TitanIcons

/// Figma "Notification": one row of a notification list, with an image or icon,
/// a title, a short message, the time, an unread dot and a chevron.
///
///     TKNotificationRow("Bài học mới", message: "Unit 3 đã mở khoá", time: "2 giờ trước",
///                       leading: .icon(.tickSquare), isUnread: true) { open(item) }
public struct TKNotificationRow: View {
    public enum Leading {
        /// A 60 pt picture with small rounded corners, e.g. a course cover.
        case image(Image)
        /// An outline icon inside a 60 pt ring.
        case icon(TKIcon)
    }

    private let title: Text
    private let message: Text?
    private let time: Text?
    private let leading: Leading?
    private let isUnread: Bool
    private let action: (() -> Void)?

    @Environment(\.theme) private var theme

    /// - Parameter action: nil hides the chevron and makes the row static.
    public init(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        time: LocalizedStringKey? = nil,
        leading: Leading? = nil,
        isUnread: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.init(title: Text(title), message: message.map { Text($0) }, time: time.map { Text($0) },
                  leading: leading, isUnread: isUnread, action: action)
    }

    public init(
        title: Text,
        message: Text? = nil,
        time: Text? = nil,
        leading: Leading? = nil,
        isUnread: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.time = time
        self.leading = leading
        self.isUnread = isUnread
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) { row }
                .buttonStyle(.plain)
        } else {
            row
        }
    }

    private var row: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            leadingView
            VStack(alignment: .leading, spacing: 6) {
                title
                    .font(theme.typography.font(size: 18, weight: .semibold, relativeTo: .headline))
                    .foregroundStyle(theme.colors.textPrimary.color)
                message?
                    .font(theme.typography.font(size: 14, weight: .medium, relativeTo: .callout))
                    .foregroundStyle(theme.colors.textSecondary.color)
                time?
                    .font(theme.typography.font(size: 12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if isUnread {
                Circle()
                    .fill(theme.colors.actionPrimary.color)
                    .frame(width: 12, height: 12)
                    .padding(.top, Spacing.sm)
                    .accessibilityHidden(true)
            }
            if action != nil {
                Image(tk: TKIcon.arrowRight2)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .padding(.top, 6)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var leadingView: some View {
        switch leading {
        case .image(let image):
            image
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .background(theme.colors.surfaceInput.color)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .accessibilityHidden(true)
        case .icon(let icon):
            Image(tk: icon)
                .renderingMode(.template)
                .resizable()
                .frame(width: 28, height: 28)
                .foregroundStyle(theme.colors.textPrimary.color)
                .frame(width: 60, height: 60)
                .overlay { Circle().strokeBorder(theme.colors.border.color, lineWidth: 1) }
                .accessibilityHidden(true)
        case nil:
            EmptyView()
        }
    }
}
