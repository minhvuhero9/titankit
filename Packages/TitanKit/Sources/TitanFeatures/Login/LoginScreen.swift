import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// A "continue with" button: the app supplies the logo, since brand marks can't ship in the kit.
public struct SocialLoginOption: Identifiable {
    public let id: AuthProvider
    public var icon: Image
    public var accessibilityLabel: LocalizedStringKey

    public init(_ provider: AuthProvider, icon: Image, accessibilityLabel: LocalizedStringKey) {
        id = provider
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct LoginConfig {
    public var socialOptions: [SocialLoginOption]
    public var showsForgotPassword: Bool
    public var showsSignUp: Bool

    public init(socialOptions: [SocialLoginOption] = [], showsForgotPassword: Bool = true, showsSignUp: Bool = true) {
        self.socialOptions = socialOptions
        self.showsForgotPassword = showsForgotPassword
        self.showsSignUp = showsSignUp
    }
}

/// Email and password sign-in, laid out like the Dolingo "sign in" screen: title, two fields,
/// forgot password, "or continue with" row, and the submit button pinned to the bottom.
public struct LoginScreen: View {
    private let config: LoginConfig
    private let onSuccess: (AuthUser) -> Void
    private let onSocial: (AuthProvider) -> Void
    private let onForgotPassword: () -> Void
    private let onSignUp: () -> Void

    @StateObject private var viewModel: LoginViewModel
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    public init(
        config: LoginConfig = LoginConfig(),
        auth: any AuthService,
        onSuccess: @escaping (AuthUser) -> Void,
        onSocial: @escaping (AuthProvider) -> Void = { _ in },
        onForgotPassword: @escaping () -> Void = {},
        onSignUp: @escaping () -> Void = {}
    ) {
        self.config = config
        self.onSuccess = onSuccess
        self.onSocial = onSocial
        self.onForgotPassword = onForgotPassword
        self.onSignUp = onSignUp
        _viewModel = StateObject(wrappedValue: LoginViewModel(auth: auth))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    fields
                    if config.showsForgotPassword { forgotPassword }
                    if !config.socialOptions.isEmpty { social }
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: Spacing.sm) {
                Divider()
                TKButton(kit(KitStrings.Login.submit), isLoading: viewModel.isLoading) {
                    Task { await submit() }
                }
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, Spacing.lg)
                if config.showsSignUp { signUp }
            }
            .padding(.bottom, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkFieldStyle(.underlined)
        .tkButtonShape(.pill)
        .tkToast($toast)
        .onChange(of: viewModel.errorKey) { key in
            toast = key.map { TKToast(KitStrings.string($0, locale: locale), style: .error) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            kit(KitStrings.Login.title)
                .tkTextStyle(.title1)
                .foregroundStyle(theme.colors.textPrimary.color)
            kit(KitStrings.Login.subtitle)
                .tkTextStyle(.body)
                .foregroundStyle(theme.colors.textSecondary.color)
        }
    }

    private var fields: some View {
        VStack(spacing: Spacing.lg) {
            TKTextField(
                label: kit(KitStrings.Login.email),
                text: $viewModel.email,
                prompt: kit(KitStrings.Login.email),
                icon: Image(tk: .message),
                status: fieldStatus(viewModel.emailErrorKey)
            )
            .textContentType(.username)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            TKTextField(
                label: kit(KitStrings.Login.password),
                text: $viewModel.password,
                prompt: kit(KitStrings.Login.password),
                icon: Image(tk: .lock),
                status: fieldStatus(viewModel.passwordErrorKey),
                kind: .secure
            )
            .textContentType(.password)
        }
    }

    private var forgotPassword: some View {
        Button(action: onForgotPassword) {
            kit(KitStrings.Login.forgotPassword)
                .tkTextStyle(.headline)
                .foregroundStyle(theme.colors.actionPrimary.color)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var social: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                line
                kit(KitStrings.Login.orContinueWith)
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .fixedSize()
                line
            }
            HStack(spacing: Spacing.md) {
                ForEach(config.socialOptions) { option in
                    Button { onSocial(option.id) } label: {
                        option.icon
                            .resizable().scaledToFit()
                            .frame(width: 24, height: 24)
                            .frame(maxWidth: .infinity, minHeight: TKButton.Size.small.height)
                            .overlay {
                                Capsule().strokeBorder(theme.colors.border.color, lineWidth: 1)
                            }
                            .contentShape(Capsule())
                    }
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .accessibilityLabel(Text(option.accessibilityLabel))
                }
            }
        }
    }

    private var signUp: some View {
        HStack(spacing: Spacing.xxs) {
            kit(KitStrings.Login.noAccount)
                .foregroundStyle(theme.colors.textSecondary.color)
            Button(action: onSignUp) {
                kit(KitStrings.Login.signUp)
                    .foregroundStyle(theme.colors.actionPrimary.color)
            }
        }
        .tkTextStyle(.callout)
    }

    private var line: some View {
        Rectangle().fill(theme.colors.border.color).frame(height: 1)
    }

    private func fieldStatus(_ errorKey: String?) -> TKFieldStatus {
        guard let errorKey else { return .normal }
        return .error(KitStrings.string(errorKey, locale: locale))
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }

    private func submit() async {
        if let user = await viewModel.signIn() {
            onSuccess(user)
        }
    }
}
