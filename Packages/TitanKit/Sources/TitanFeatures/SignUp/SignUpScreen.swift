import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Email sign-up, one question per page like the Dolingo screens: "what should we call you?",
/// then the email, then the password twice, with "Creating an account..." while it runs.
///
///     SignUpScreen(auth: container.auth, onExit: { flow.leaveSignUp() }) { user in
///         flow.didSignUp(user)
///     }
public struct SignUpScreen: View {
    private let onExit: () -> Void
    private let onSuccess: (AuthUser) -> Void

    @StateObject private var viewModel: SignUpViewModel
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - name: fills in the first step, e.g. a name the user gave earlier.
    ///   - onExit: back on the first step.
    public init(
        auth: any AuthService,
        name: String = "",
        onExit: @escaping () -> Void,
        onSuccess: @escaping (AuthUser) -> Void
    ) {
        self.onExit = onExit
        self.onSuccess = onSuccess
        _viewModel = StateObject(wrappedValue: SignUpViewModel(auth: auth, name: name))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    title
                        .tkTextStyle(.title1)
                        .foregroundStyle(theme.colors.textPrimary.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    fields
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: Spacing.sm) {
                Divider()
                TKButton(kit(viewModel.step == .password ? KitStrings.SignUp.submit : KitStrings.continueAction)) {
                    Task {
                        if let user = await viewModel.next() { onSuccess(user) }
                    }
                }
                .disabled(!viewModel.canContinue)
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkFieldStyle(.underlined)
        .tkButtonShape(.pill)
        .tkNavigationBar(title: Text(verbatim: ""), onBack: { if !viewModel.back() { onExit() } })
        .tkToast($toast)
        .tkModal(isPresented: .constant(viewModel.isCreating)) {
            TKModal(title: kit(KitStrings.SignUp.creating), isLoading: true)
        }
        .onChange(of: viewModel.errorKey) { key in
            toast = key.map { TKToast(KitStrings.string($0, locale: locale), style: .error) }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.step)
    }

    private var title: Text {
        switch viewModel.step {
        case .name:
            kit(KitStrings.SignUp.nameTitle)
        case .email:
            Text(verbatim: String(format: KitStrings.string(KitStrings.SignUp.emailTitle, locale: locale), viewModel.trimmedName))
        case .password:
            kit(KitStrings.SignUp.passwordTitle)
        }
    }

    @ViewBuilder
    private var fields: some View {
        switch viewModel.step {
        case .name:
            TKTextField(label: kit(KitStrings.SignUp.nameLabel), text: $viewModel.name,
                        prompt: kit(KitStrings.SignUp.nameLabel))
                .textContentType(.givenName)
                .submitLabel(.next)
        case .email:
            TKTextField(label: kit(KitStrings.Login.email), text: $viewModel.email,
                        prompt: kit(KitStrings.Login.email), icon: Image(tk: .message),
                        status: status(viewModel.emailErrorKey))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        case .password:
            VStack(spacing: Spacing.lg) {
                TKTextField(label: kit(KitStrings.Login.password), text: $viewModel.password,
                            prompt: kit(KitStrings.Login.password), icon: Image(tk: .lock),
                            status: status(viewModel.passwordErrorKey), kind: .secure)
                    .textContentType(.newPassword)
                TKTextField(label: kit(KitStrings.SignUp.confirmPassword), text: $viewModel.confirmPassword,
                            prompt: kit(KitStrings.SignUp.confirmPassword), icon: Image(tk: .lock),
                            status: status(viewModel.confirmErrorKey), kind: .secure)
                    .textContentType(.newPassword)
            }
        }
    }

    private func status(_ errorKey: String?) -> TKFieldStatus {
        guard let errorKey else { return .normal }
        return .error(KitStrings.string(errorKey, locale: locale))
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}
