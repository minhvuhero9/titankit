import SwiftUI
import TitanCore

/// Centered icon, title, message and an optional button. Used for empty lists and errors.
public struct TKEmptyState: View {
    private let icon: Image
    private let title: Text
    private let message: Text?
    private let actionTitle: Text?
    private let action: (() -> Void)?

    @Environment(\.theme) private var theme

    public init(
        icon: Image,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(icon: icon, title: Text(title), message: message.map { Text($0) },
                  actionTitle: actionTitle.map { Text($0) }, action: action)
    }

    init(icon: Image, title: Text, message: Text?, actionTitle: Text?, action: (() -> Void)?) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.md) {
            icon
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(theme.colors.actionPrimary.color)
                .accessibilityHidden(true)
            VStack(spacing: Spacing.xs) {
                title
                    .tkTextStyle(.title3)
                    .foregroundStyle(theme.colors.textPrimary.color)
                message?
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) { actionTitle }
                    .buttonStyle(.tkFilled)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shows a TitanError with its Vietnamese message and a retry button.
public struct TKErrorView: View {
    private let error: TitanError
    private let retry: (() -> Void)?

    /// - Parameter retry: shown as "Thử lại" when given.
    public init(error: TitanError, retry: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        // Kit strings move to TitanLocalization in phase 3.
        TKEmptyState(
            icon: Image(systemName: error == .network(.offline) ? "wifi.slash" : "exclamationmark.triangle"),
            title: Text(error == .network(.offline) ? "Mất kết nối" : "Có lỗi xảy ra"),
            message: Text(error.userMessage),
            actionTitle: retry == nil ? nil : Text("Thử lại"),
            action: retry
        )
    }
}

/// Medium primary button style for actions whose title is already a Text.
struct TKFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FilledBody(configuration: configuration)
    }

    private struct FilledBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.theme) private var theme

        var body: some View {
            configuration.label
                .font(theme.typography.font(size: TKButton.Size.medium.fontSize, weight: .bold, relativeTo: .headline))
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .padding(.horizontal, Spacing.lg)
                .frame(minHeight: TKButton.Size.medium.height)
                .background(theme.colors.actionPrimary.color, in: Capsule())
                .opacity(configuration.isPressed ? 0.8 : 1)
        }
    }
}

extension ButtonStyle where Self == TKFilledButtonStyle {
    static var tkFilled: TKFilledButtonStyle { TKFilledButtonStyle() }
}
