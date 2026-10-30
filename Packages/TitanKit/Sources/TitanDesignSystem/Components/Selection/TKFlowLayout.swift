import SwiftUI

/// Lays views out left to right and wraps to a new line when the row is full, like the topic
/// chips of the Dolingo sign-up questionnaire.
///
///     TKFlowLayout {
///         ForEach(topics) { topic in
///             TKChip(title: topic.name, style: picked.contains(topic) ? .filled : .neutral) { toggle(topic) }
///         }
///     }
public struct TKFlowLayout: Layout {
    private let spacing: CGFloat
    private let lineSpacing: CGFloat

    /// - Parameters:
    ///   - spacing: between views on the same line.
    ///   - lineSpacing: between lines.
    public init(spacing: CGFloat = Spacing.xs, lineSpacing: CGFloat = Spacing.sm) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return Self.arrange(sizes, width: proposal.width ?? .infinity, spacing: spacing, lineSpacing: lineSpacing).size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let layout = Self.arrange(sizes, width: bounds.width, spacing: spacing, lineSpacing: lineSpacing)
        for index in subviews.indices {
            let origin = layout.origins[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(sizes[index])
            )
        }
    }

    /// Where each view goes and the size of the whole block. A view wider than the line gets
    /// a line of its own.
    nonisolated static func arrange(
        _ sizes: [CGSize],
        width: CGFloat,
        spacing: CGFloat,
        lineSpacing: CGFloat
    ) -> (origins: [CGPoint], size: CGSize) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var widest: CGFloat = 0
        for size in sizes {
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return (origins, CGSize(width: widest, height: sizes.isEmpty ? 0 : y + lineHeight))
    }
}
