import SwiftUI

public extension View {
    /// The outlined card of the Settings, Paywall and Select Country pages: background colour,
    /// a 2 pt border with a thicker bottom edge, and a brand border while selected.
    ///
    ///     PlanDetails().padding(Spacing.lg).tkOutlinedCard()
    ///     CountryRow().padding(Spacing.md).tkOutlinedCard(isSelected: picked == country)
    func tkOutlinedCard(isSelected: Bool = false, cornerRadius: CGFloat = 12) -> some View {
        modifier(TKOutlinedCardModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}

private struct TKOutlinedCardModifier: ViewModifier {
    let isSelected: Bool
    let cornerRadius: CGFloat

    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let edge = (isSelected ? theme.colors.actionPrimary : theme.colors.border).color
        content
            .background {
                ZStack {
                    // The bottom edge: the border colour peeking out 3 pt below the card.
                    shape.fill(edge).offset(y: TKOutlinedCardMetrics.bottomEdge)
                    shape.fill(theme.colors.surfaceBackground.color)
                    shape.strokeBorder(edge, lineWidth: TKOutlinedCardMetrics.borderWidth(isSelected: isSelected))
                }
            }
            .padding(.bottom, TKOutlinedCardMetrics.bottomEdge)
            .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

enum TKOutlinedCardMetrics {
    /// Figma draws the bottom border 5 pt thick against 2 pt on the other sides.
    static let bottomEdge: CGFloat = 3

    static func borderWidth(isSelected: Bool) -> CGFloat {
        isSelected ? 3 : 2
    }
}
