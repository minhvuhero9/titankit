import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Forgot password, laid out like the Dolingo screens: "Forgot your password?" with the email,
/// "Enter OTP code" with a countdown before the code can be resent, "Secure your account" with
/// the new password twice, then "You're all set!" which signs in.
///
///     PasswordResetScreen(auth: container.auth, onExit: { flow.backToLogin() }) { user in
///         flow.didSignIn()
///     }
public struct PasswordResetScreen: View {
    private let onExit: () -> Void
    private let onSignedIn: (AuthUser) -> Void

    @StateObject private var viewModel: PasswordResetViewModel
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - email: fills in the first step.
    ///   - onExit: back on the first step, or when signing in after the reset fails.
    ///   - onSignedIn: "Continue" on the last step signed in with the new password.
    public init(
        auth: any AuthService,
        email: String = "",
        codeLength: Int = 4,
        onExit: @escaping () -> Void,
        onSignedIn: @escaping (AuthUser) -> Void
    ) {
        self.onExit = onExit
        self.onSignedIn = onSignedIn
        _viewModel = StateObject(wrappedValue: PasswordResetViewModel(auth: auth, email: email, codeLength: codeLength))
    }

    public var body: some View {
        Group {
            if viewModel.step == .done {
                SuccessScreen(
                    title: kit(KitStrings.PasswordReset.doneTitle),
                    message: kit(KitStrings.PasswordReset.doneMessage),
                    actionTitle: kit(KitStrings.PasswordReset.doneAction),
                    style: .checkmark
                ) {
                    Task { await submit() }
                }
                .tkModal(isPresented: .constant(viewModel.isLoading)) {
                    TKModal(title: kit(KitStrings.loading), isLoading: true)
                }
            } else {
                form
                    .tkNavigationBar(title: Text(verbatim: ""), onBack: { if !viewModel.back() { onExit() } })
            }
        }
        .tkToast($toast)
        .onChange(of: viewModel.errorKey) { key in
            toast = key.map { TKToast(KitStrings.string($0, locale: locale), style: .error) }
        }
        .onChange(of: viewModel.noticeKey) { key in
            toast = key.map { TKToast(KitStrings.string($0, locale: locale), style: .success) }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.step)
    }

    private var form: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    fields
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.step != .code {
                VStack(spacing: Spacing.sm) {
                    Divider()
                    TKButton(kit(submitKey), isLoading: viewModel.isLoading) {
                        Task { await submit() }
                    }
                    .disabled(!viewModel.canContinue)
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, Spacing.sm)
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkFieldStyle(.underlined)
        .tkButtonShape(.pill)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            title
                .tkTextStyle(.title1)
                .foregroundStyle(theme.colors.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            message
                .tkTextStyle(.body)
                .foregroundStyle(theme.colors.textSecondary.color)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var title: Text {
        switch viewModel.step {
        case .email, .done: kit(KitStrings.PasswordReset.emailTitle)
        case .code: kit(KitStrings.PasswordReset.codeTitle)
        case .password: kit(KitStrings.PasswordReset.passwordTitle)
        }
    }

    private var message: Text {
        switch viewModel.step {
        case .email, .done:
            kit(KitStrings.PasswordReset.emailMessage)
        case .code:
            Text(verbatim: String(format: KitStrings.string(KitStrings.PasswordReset.codeMessage, locale: locale),
                                  viewModel.trimmedEmail))
        case .password:
            kit(KitStrings.PasswordReset.passwordMessage)
        }
    }

    private var submitKey: String {
        viewModel.step == .password ? KitStrings.PasswordReset.passwordSubmit : KitStrings.PasswordReset.emailSubmit
    }

    @ViewBuilder
    private var fields: some View {
        switch viewModel.step {
        case .email, .done:
            TKTextField(label: kit(KitStrings.Login.email), text: $viewModel.email,
                        prompt: kit(KitStrings.Login.email), icon: Image(tk: .message),
                        status: status(viewModel.emailErrorKey))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .onSubmit { Task { await submit() } }
        case .code:
            codeEntry
        case .password:
            VStack(spacing: Spacing.lg) {
                TKTextField(label: kit(KitStrings.PasswordReset.newPassword), text: $viewModel.password,
                            prompt: kit(KitStrings.PasswordReset.newPassword), icon: Image(tk: .lock),
                            status: status(viewModel.passwordErrorKey), kind: .secure)
                    .textContentType(.newPassword)
                TKTextField(label: kit(KitStrings.PasswordReset.confirmPassword), text: $viewModel.confirmPassword,
                            prompt: kit(KitStrings.PasswordReset.confirmPassword), icon: Image(tk: .lock),
                            status: status(viewModel.confirmErrorKey), kind: .secure)
                    .textContentType(.newPassword)
            }
        }
    }

    private var codeEntry: some View {
        VStack(spacing: Spacing.lg) {
            TKCodeField(code: $viewModel.code, length: viewModel.codeLength, isError: viewModel.isCodeWrong)
                .disabled(viewModel.isLoading)
                .accessibilityLabel(kit(KitStrings.PasswordReset.codeLabel))
                .onChange(of: viewModel.code) { code in
                    // The code checks itself once every digit is in.
                    if code.count == viewModel.codeLength { Task { await submit() } }
                }
            if viewModel.isLoading {
                ProgressView()
                    .tint(theme.colors.actionPrimary.color)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    resend(secondsLeft: viewModel.secondsUntilResend(at: context.date))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func resend(secondsLeft: Int) -> some View {
        VStack(spacing: Spacing.md) {
            if secondsLeft > 0 {
                Text(verbatim: String(format: KitStrings.string(KitStrings.PasswordReset.resendIn, locale: locale), secondsLeft))
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .monospacedDigit()
            }
            Button {
                Task { await viewModel.resend() }
            } label: {
                kit(KitStrings.PasswordReset.resend)
                    .tkTextStyle(.headline)
                    .foregroundStyle((secondsLeft > 0 ? theme.colors.textDisabled : theme.colors.actionPrimary).color)
            }
            .disabled(secondsLeft > 0)
        }
        .multilineTextAlignment(.center)
    }

    private func status(_ errorKey: String?) -> TKFieldStatus {
        guard let errorKey else { return .normal }
        return .error(KitStrings.string(errorKey, locale: locale))
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }

    private func submit() async {
        let wasDone = viewModel.step == .done
        if let user = await viewModel.next() {
            onSignedIn(user)
        } else if wasDone {
            // The password is changed; signing in again from the sign-in screen will work.
            onExit()
        }
    }
}
