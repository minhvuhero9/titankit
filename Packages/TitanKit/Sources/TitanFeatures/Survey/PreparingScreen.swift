import SwiftUI
import TitanDesignSystem

/// "Preparing a personalized learning plan for you...": a title, a big ring counting up to 100 %
/// and a line at the bottom. Calls `onFinish` once the ring is full and `work` has returned.
///
///     PreparingScreen(title: Text("plan.preparing.title"), message: Text("plan.preparing.message"),
///                     work: { await repository.buildPlan() }, onFinish: { flow.planIsReady() })
public struct PreparingScreen: View {
    private let title: Text
    private let message: Text?
    private let duration: Duration
    private let work: @Sendable () async -> Void
    private let onFinish: () -> Void

    @State private var progress = 0.0
    @Environment(\.theme) private var theme

    /// - Parameters:
    ///   - duration: how long the ring takes to fill, even when `work` is quicker.
    ///   - work: runs while the ring fills, e.g. saving the answers.
    public init(
        title: Text,
        message: Text? = nil,
        duration: Duration = .seconds(3),
        work: @escaping @Sendable () async -> Void = {},
        onFinish: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.duration = duration
        self.work = work
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            title
                .tkTextStyle(.title1)
                .foregroundStyle(theme.colors.textPrimary.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            TKProgressRing(progress, size: 240) {
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(theme.typography.font(size: 56, weight: .bold, relativeTo: .display))
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .monospacedDigit()
            }
            Spacer()
            message?
                .tkTextStyle(.callout)
                .foregroundStyle(theme.colors.textSecondary.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .task { await run() }
    }

    private func run() async {
        let work = work
        async let finished: Void = work()
        let ticks = 50
        for tick in 1...ticks {
            do { try await Task.sleep(for: duration / ticks) } catch { return }
            progress = Self.progress(tick: tick, of: ticks)
        }
        await finished
        onFinish()
    }

    /// The ring stops at 99 % until the last tick, so 100 % only shows once everything is done.
    nonisolated static func progress(tick: Int, of ticks: Int) -> Double {
        guard ticks > 0 else { return 1 }
        return tick >= ticks ? 1 : min(Double(tick) / Double(ticks), 0.99)
    }
}
