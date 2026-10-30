import SwiftUI
import TitanAuth
import TitanCore
import TitanDesignSystem
import TitanLocalization

/// A provider row of the Linked Accounts screen. The app supplies the logo, since brand marks
/// can't ship in the kit.
public struct LinkedAccountOption: Identifiable {
    public let id: AuthProvider
    public var icon: Image
    public var name: String

    public init(_ provider: AuthProvider, icon: Image, name: String) {
        id = provider
        self.icon = icon
        self.name = name
    }
}

/// Figma "settings - linked accounts": one card per provider with "Linked" or "Link".
/// Linking a guest account keeps its progress under Google or Apple; unlinking asks first and
/// is refused for the last way to sign in.
///
///     LinkedAccountsScreen(auth: auth, options: [LinkedAccountOption(.google, icon: logo, name: "Google")],
///                          credential: { try await signInSheet(for: $0) }, onBack: { router.pop() })
public struct LinkedAccountsScreen: View {
    private let options: [LinkedAccountOption]
    private let onBack: () -> Void

    @StateObject private var viewModel: LinkedAccountsViewModel
    @State private var unlinking: LinkedAccountOption?
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    public init(
        auth: any AuthService,
        options: [LinkedAccountOption],
        credential: @escaping CredentialRequest,
        onBack: @escaping () -> Void
    ) {
        self.options = options
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: LinkedAccountsViewModel(auth: auth, credential: credential))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(options) { option in
                    row(option)
                }
            }
            .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: kit(KitStrings.LinkedAccounts.title), onBack: onBack)
        .tkToast($toast)
        .tkSheet(isPresented: Binding(get: { unlinking != nil }, set: { if !$0 { unlinking = nil } })) {
            if let option = unlinking {
                TKSheet(
                    title: Text(verbatim: format(KitStrings.LinkedAccounts.unlinkTitle, option.name)),
                    titleColor: theme.colors.feedbackError.color,
                    primary: TKModalAction(title: kit(KitStrings.LinkedAccounts.unlink)) {
                        unlinking = nil
                        Task { await viewModel.unlink(option.id) }
                    },
                    secondary: TKModalAction(title: kit(KitStrings.cancel)) { unlinking = nil }
                ) {
                    Text(verbatim: format(KitStrings.LinkedAccounts.unlinkMessage, option.name))
                        .tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textSecondary.color)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.errorKey) { key in
            guard let key else { return }
            toast = TKToast(KitStrings.string(key, locale: locale), style: .error)
            viewModel.dismissMessages()
        }
        .onChange(of: viewModel.lastChange?.provider) { _ in
            guard let change = viewModel.lastChange,
                  let option = options.first(where: { $0.id == change.provider }) else { return }
            let key = change.isLinked ? KitStrings.LinkedAccounts.didLink : KitStrings.LinkedAccounts.didUnlink
            toast = TKToast(format(key, option.name), style: .success)
            viewModel.dismissMessages()
        }
    }

    private func row(_ option: LinkedAccountOption) -> some View {
        let isLinked = viewModel.isLinked(option.id)
        return Button {
            if isLinked {
                if viewModel.canUnlink(option.id) {
                    unlinking = option
                } else {
                    toast = TKToast(KitStrings.string(KitStrings.LinkedAccounts.lastProvider, locale: locale), style: .info)
                }
            } else {
                Task { await viewModel.link(option.id) }
            }
        } label: {
            HStack(spacing: Spacing.md) {
                option.icon
                    .resizable().scaledToFit()
                    .frame(width: 40, height: 40)
                    .accessibilityHidden(true)
                Text(verbatim: option.name)
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.textPrimary.color)
                Spacer()
                if viewModel.busy == option.id {
                    ProgressView().tint(theme.colors.actionPrimary.color)
                } else {
                    kit(isLinked ? KitStrings.LinkedAccounts.linked : KitStrings.LinkedAccounts.link)
                        .tkTextStyle(.callout)
                        .foregroundStyle((isLinked ? theme.colors.textSecondary : theme.colors.actionPrimary).color)
                }
            }
            .padding(Spacing.lg)
            .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.busy != nil)
        .accessibilityValue(kit(isLinked ? KitStrings.LinkedAccounts.linked : KitStrings.LinkedAccounts.link))
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }

    private func format(_ key: String, _ name: String) -> String {
        String(format: KitStrings.string(key, locale: locale), name)
    }
}
