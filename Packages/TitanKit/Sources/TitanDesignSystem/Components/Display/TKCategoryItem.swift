import SwiftUI

/// Figma "Category Menu": a round tinted icon with a label under it, for a grid of categories.
///
///     LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
///         TKCategoryItem("Ngữ pháp", icon: Image(tk: .document, style: .bold)) { open(.grammar) }
///     }
public struct TKCategoryItem: View {
    private let title: Text
    private let icon: Image
    private let action: () -> Void

    @Environment(\.theme) private var theme

    public init(_ title: LocalizedStringKey, icon: Image, action: @escaping () -> Void) {
        self.init(title: Text(title), icon: icon, action: action)
    }

    public init(title: Text, icon: Image, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(theme.colors.actionPrimary.color)
                    .frame(width: 60, height: 60)
                    .background(theme.colors.actionSecondary.color, in: Circle())
                title
                    .font(theme.typography.font(size: 16, weight: .semibold, relativeTo: .callout))
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
