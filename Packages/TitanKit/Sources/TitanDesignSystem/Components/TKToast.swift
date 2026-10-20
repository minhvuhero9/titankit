import SwiftUI
import UIKit

/// A short message that slides in at the top and hides itself.
///
///     @State private var toast: TKToast?
///     ...
///     .tkToast($toast)
///     toast = TKToast("Đã lưu", style: .success)
public struct TKToast: Identifiable, Equatable, Sendable {
    public enum Style: String, CaseIterable, Sendable {
        case info, success, warning, error
    }

    public let id = UUID()
    public var message: String
    public var style: Style
    public var duration: Duration

    public init(_ message: String, style: Style = .info, duration: Duration = .seconds(3)) {
        self.message = message
        self.style = style
        self.duration = duration
    }

    var systemImage: String {
        switch style {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    func tint(in colors: ColorTokens) -> AdaptiveColor {
        switch style {
        case .info: colors.feedbackInfo
        case .success: colors.feedbackSuccess
        case .warning: colors.feedbackWarning
        case .error: colors.feedbackError
        }
    }
}

public extension View {
    /// Shows the toast while the binding is non-nil, then sets it back to nil.
    func tkToast(_ toast: Binding<TKToast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: TKToast?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast {
                    ToastView(toast: toast)
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.xs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { self.toast = nil }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toast)
            .task(id: toast?.id) { @MainActor in
                guard let current = toast else { return }
                UIAccessibility.post(notification: .announcement, argument: current.message)
                try? await Task.sleep(for: current.duration)
                if toast?.id == current.id { toast = nil }
            }
    }
}

private struct ToastView: View {
    let toast: TKToast
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.systemImage)
                .foregroundStyle(toast.tint(in: theme.colors).color)
            Text(toast.message)
                .tkTextStyle(.callout)
                .foregroundStyle(theme.colors.textPrimary.color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(
            theme.colors.surfaceBackground.color,
            in: RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                .strokeBorder(theme.colors.border.color, lineWidth: 1)
        }
        .tkElevation(.card)
        .accessibilityElement(children: .combine)
    }
}
