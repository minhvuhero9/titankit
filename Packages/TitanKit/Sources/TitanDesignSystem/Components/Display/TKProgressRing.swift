import SwiftUI

/// Figma "Goals Percentage": a ring that fills clockwise from the top, with an optional label inside.
///
///     TKProgressRing(0.3)
///     TKProgressRing(vm.goal, size: 64) { Text("\(vm.minutes)") }
public struct TKProgressRing<Label: View>: View {
    private let progress: Double
    private let size: CGFloat
    private let label: Label

    @Environment(\.theme) private var theme

    /// - Parameters:
    ///   - progress: 0...1; values outside are clamped.
    ///   - size: diameter. Figma's ring is 42 with a 3 pt line.
    public init(_ progress: Double, size: CGFloat = 42, @ViewBuilder label: () -> Label) {
        self.progress = Self.clamped(progress)
        self.size = size
        self.label = label()
    }

    public var body: some View {
        let lineWidth = Self.lineWidth(for: size)
        ZStack {
            Circle()
                .stroke(theme.colors.border.color, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(theme.colors.actionPrimary.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label
        }
        .padding(lineWidth / 2)
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.3), value: progress)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }

    nonisolated static func clamped(_ value: Double) -> Double {
        value.isNaN ? 0 : min(max(value, 0), 1)
    }

    /// Figma draws the ring with an inner radius of 85%, so the line is 7.5% of the diameter.
    nonisolated static func lineWidth(for size: CGFloat) -> CGFloat {
        max(2, size * 0.075)
    }
}

public extension TKProgressRing where Label == EmptyView {
    init(_ progress: Double, size: CGFloat = 42) {
        self.init(progress, size: size) { EmptyView() }
    }
}
