import SwiftUI

/// Full-area spinner in the brand colour, with an optional message.
public struct TKLoadingView: View {
    private let message: Text?
    @Environment(\.theme) private var theme

    public init(_ message: LocalizedStringKey? = nil) {
        self.message = message.map { Text($0) }
    }

    public var body: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .controlSize(.large)
                .tint(theme.colors.actionPrimary.color)
            message?
                .tkTextStyle(.callout)
                .foregroundStyle(theme.colors.textSecondary.color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public extension View {
    /// Grey placeholder shapes that pulse while content loads.
    ///
    ///     ProfileHeader(user: .placeholder).tkSkeleton(vm.state.isLoading)
    func tkSkeleton(_ isActive: Bool) -> some View {
        modifier(SkeletonModifier(isActive: isActive))
    }
}

private struct SkeletonModifier: ViewModifier {
    let isActive: Bool
    @State private var dimmed = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            content
                .redacted(reason: .placeholder)
                .opacity(dimmed ? 0.4 : 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { dimmed = true }
                }
        } else {
            content
        }
    }
}
