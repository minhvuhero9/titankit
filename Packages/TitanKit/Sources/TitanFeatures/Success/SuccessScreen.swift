import SwiftUI
import TitanDesignSystem

/// A full screen "done" page: the success illustration, a title, a message and one button.
/// Dolingo uses it for "Your plan is ready!", "Reset password successful" and a new subscription.
///
///     SuccessScreen(title: Text("plan.ready.title"), message: Text("plan.ready.message"),
///                   actionTitle: Text("plan.ready.action")) { flow.createAccount() }
public struct SuccessScreen: View {
    private let title: Text
    private let message: Text?
    private let actionTitle: Text
    private let style: TKSuccessIllustration.Style
    private let action: () -> Void

    @Environment(\.theme) private var theme

    public init(
        title: Text,
        message: Text? = nil,
        actionTitle: Text,
        style: TKSuccessIllustration.Style = .confetti,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.style = style
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            TKSuccessIllustration(style)
            VStack(spacing: Spacing.sm) {
                title
                    .tkTextStyle(.title1)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .accessibilityAddTraits(.isHeader)
                message?
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            TKButton(actionTitle, shape: .pill, action: action)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
    }
}
