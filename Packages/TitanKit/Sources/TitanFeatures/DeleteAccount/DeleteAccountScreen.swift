import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Account deletion, as App Review requires for apps with sign-up: what will be lost,
/// a tick to confirm, then a last question in a bottom sheet before deleting.
///
///     DeleteAccountScreen(auth: container.auth, onBack: { router.pop() },
///                         onDeleted: { flow.didDeleteAccount() })
public struct DeleteAccountScreen: View {
    private let consequences: [Text]?
    private let onBack: (() -> Void)?
    private let onDeleted: () -> Void

    @StateObject private var viewModel: DeleteAccountViewModel
    @State private var confirming = false
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameter consequences: what the user loses, one line each; the kit's list by default.
    public init(
        auth: any AuthService,
        consequences: [Text]? = nil,
        onBack: (() -> Void)? = nil,
        onDeleted: @escaping () -> Void
    ) {
        self.consequences = consequences
        self.onBack = onBack
        self.onDeleted = onDeleted
        _viewModel = StateObject(wrappedValue: DeleteAccountViewModel(auth: auth))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    TKAlert(title: kit(KitStrings.DeleteAccount.warning), status: .error)
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        ForEach(lines.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Image(tk: .closeSquare)
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(theme.colors.feedbackError.color)
                                    .accessibilityHidden(true)
                                lines[index]
                                    .font(theme.typography.font(size: 18, weight: .regular, relativeTo: .body))
                                    .foregroundStyle(theme.colors.textPrimary.color)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    Toggle(isOn: $viewModel.hasConfirmed) {
                        kit(KitStrings.DeleteAccount.confirmCheck)
                            .font(theme.typography.font(size: 16, weight: .semibold, relativeTo: .callout))
                            .foregroundStyle(theme.colors.textPrimary.color)
                    }
                    .toggleStyle(.tkCheckbox)
                }
                .padding(Spacing.lg)
            }

            deleteButton
                .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: kit(KitStrings.DeleteAccount.title), onBack: onBack)
        .tkToast($toast)
        .onChange(of: viewModel.errorKey) { key in
            if let key { toast = TKToast(KitStrings.string(key, locale: locale), style: .error) }
        }
        .tkSheet(isPresented: $confirming) {
            TKSheet(
                title: kit(KitStrings.DeleteAccount.confirmTitle),
                titleColor: theme.colors.feedbackError.color,
                primary: TKModalAction(title: kit(KitStrings.DeleteAccount.action)) {
                    confirming = false
                    Task {
                        if await viewModel.delete() { onDeleted() }
                    }
                },
                secondary: TKModalAction(title: kit(KitStrings.cancel)) { confirming = false }
            )
        }
    }

    /// Red pill: the kit's buttons only come in brand colours.
    private var deleteButton: some View {
        Button { confirming = true } label: {
            ZStack {
                if viewModel.isDeleting {
                    ProgressView().tint(theme.colors.actionOnPrimary.color)
                } else {
                    kit(KitStrings.DeleteAccount.action)
                        .font(theme.typography.font(size: 18, weight: .bold, relativeTo: .headline))
                }
            }
            .foregroundStyle(theme.colors.actionOnPrimary.color)
            .frame(maxWidth: .infinity, minHeight: TKButton.Size.large.height)
            .background(theme.colors.feedbackError.color.opacity(viewModel.canDelete ? 1 : 0.4), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canDelete)
    }

    private var lines: [Text] {
        consequences ?? [
            kit(KitStrings.DeleteAccount.lossProgress),
            kit(KitStrings.DeleteAccount.lossProfile),
            kit(KitStrings.DeleteAccount.lossSubscription),
        ]
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}
