import SwiftUI

/// A block of content on the card colour, with the theme's large radius and a soft shadow.
public struct TKCard<Content: View>: View {
    private let padding: CGFloat
    private let elevation: Elevation
    private let content: Content

    @Environment(\.theme) private var theme

    public init(padding: CGFloat = Spacing.md, elevation: Elevation = .card, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.elevation = elevation
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                theme.colors.surfaceCard.color,
                in: RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
            )
            .tkElevation(elevation)
    }
}
