import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Personal info: avatar with initials, an editable name, the email (read only) and a
/// "Delete account" link at the bottom. Saving calls `AuthService.updateProfile`.
///
///     ProfileScreen(auth: container.auth, onBack: { router.pop() },
///                   onDeleteAccount: { router.push(.deleteAccount) })
public struct ProfileScreen: View {
    private let onBack: (() -> Void)?
    private let onSaved: (AuthUser) -> Void
    private let onDeleteAccount: (() -> Void)?

    @StateObject private var viewModel: ProfileViewModel
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameter onDeleteAccount: shows the "Delete account" row when given.
    public init(
        auth: any AuthService,
        onBack: (() -> Void)? = nil,
        onSaved: @escaping (AuthUser) -> Void = { _ in },
        onDeleteAccount: (() -> Void)? = nil
    ) {
        self.onBack = onBack
        self.onSaved = onSaved
        self.onDeleteAccount = onDeleteAccount
        _viewModel = StateObject(wrappedValue: ProfileViewModel(auth: auth))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    TKAvatar(name: viewModel.name.isEmpty ? viewModel.user?.email : viewModel.name, size: 120)
                        .padding(.top, Spacing.md)
                    VStack(spacing: Spacing.lg) {
                        TKTextField(
                            label: kit(KitStrings.Profile.name),
                            text: $viewModel.name,
                            prompt: kit(KitStrings.Profile.name),
                            icon: Image(tk: .profile)
                        )
                        .textContentType(.name)
                        if let email = viewModel.user?.email {
                            TKTextField(
                                label: kit(KitStrings.Profile.email),
                                text: .constant(email),
                                icon: Image(tk: .message)
                            )
                            .disabled(true)
                        }
                    }
                    if let onDeleteAccount {
                        TKSettingsRow(
                            title: kit(KitStrings.DeleteAccount.title),
                            icon: Image(tk: .delete),
                            role: .destructive,
                            action: onDeleteAccount
                        )
                    }
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)

            TKButton(kit(KitStrings.Profile.save), style: .threeD, shape: .pill, isLoading: viewModel.isSaving) {
                Task { await save() }
            }
            .disabled(!viewModel.canSave)
            .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: kit(KitStrings.Profile.title), onBack: onBack)
        .tkToast($toast)
        .task { await viewModel.load() }
        .onChange(of: viewModel.errorKey) { key in
            if let key { toast = TKToast(KitStrings.string(key, locale: locale), style: .error) }
        }
    }

    private func save() async {
        guard let user = await viewModel.save() else { return }
        toast = TKToast(KitStrings.string(KitStrings.Profile.saved, locale: locale), style: .success)
        onSaved(user)
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}
