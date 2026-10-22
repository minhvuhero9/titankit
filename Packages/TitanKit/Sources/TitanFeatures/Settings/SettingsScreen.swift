import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// One row of `SettingsScreen`. The app picks the ids and reacts to them in `onSelect`.
public struct SettingsItem: Identifiable {
    public let id: String
    let title: Text
    let icon: Image?
    let accessory: TKSettingsRow.Accessory
    let role: TKSettingsRow.Role

    public init(
        _ id: String,
        title: LocalizedStringKey,
        icon: Image? = nil,
        accessory: TKSettingsRow.Accessory = .chevron,
        role: TKSettingsRow.Role = .normal
    ) {
        self.init(id, title: Text(title), icon: icon, accessory: accessory, role: role)
    }

    public init(
        _ id: String,
        title: Text,
        icon: Image? = nil,
        accessory: TKSettingsRow.Accessory = .chevron,
        role: TKSettingsRow.Role = .normal
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.accessory = accessory
        self.role = role
    }
}

/// A white card of settings rows. A screen can have several.
public struct SettingsSection: Identifiable {
    public let id: String
    let items: [SettingsItem]

    public init(_ id: String = UUID().uuidString, items: [SettingsItem]) {
        self.id = id
        self.items = items
    }
}

/// Figma "Account & Settings": an optional header (upgrade banner, profile card), cards of rows,
/// and a red Logout row that asks for confirmation.
///
///     SettingsScreen(sections: [
///         SettingsSection(items: [
///             SettingsItem("appearance", title: Text.kit(KitStrings.Settings.appearance, locale: locale), icon: Image(tk: .show)),
///         ]),
///     ], onSelect: { id in router.push(...) }, onLogout: { await flow.signOut() }) {
///         TKUpgradeBanner(title: Text("Nâng cấp ngay!")) { router.present(.paywall) }
///     }
///
/// The screen never navigates: rows report their id through `onSelect`.
public struct SettingsScreen<Header: View>: View {
    private let title: Text?
    private let sections: [SettingsSection]
    private let onBack: (() -> Void)?
    private let onSelect: (String) -> Void
    private let onLogout: (() async -> Void)?
    private let header: Header

    @State private var confirmingLogout = false
    @State private var isLoggingOut = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - title: "Tài khoản" by default.
    ///   - onBack: shows a back arrow when given, e.g. when the screen is pushed.
    ///   - onLogout: adds the Logout row; runs after the user confirms.
    public init(
        title: Text? = nil,
        sections: [SettingsSection],
        onBack: (() -> Void)? = nil,
        onSelect: @escaping (String) -> Void,
        onLogout: (() async -> Void)? = nil,
        @ViewBuilder header: () -> Header
    ) {
        self.title = title
        self.sections = sections
        self.onBack = onBack
        self.onSelect = onSelect
        self.onLogout = onLogout
        self.header = header()
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                header
                ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                    card(section.items, withLogout: index == sections.count - 1)
                }
                if sections.isEmpty, onLogout != nil {
                    card([], withLogout: true)
                }
            }
            .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: title ?? kit(KitStrings.Settings.title), onBack: onBack)
        .disabled(isLoggingOut)
        .overlay {
            if isLoggingOut {
                ProgressView().controlSize(.large).tint(theme.colors.actionPrimary.color)
            }
        }
        .tkSheet(isPresented: $confirmingLogout) {
            TKSheet(
                title: kit(KitStrings.Settings.logout),
                titleColor: theme.colors.feedbackError.color,
                primary: TKModalAction(title: kit(KitStrings.Settings.logoutAction)) { logOut() },
                secondary: TKModalAction(title: kit(KitStrings.cancel)) { confirmingLogout = false }
            ) {
                kit(KitStrings.Settings.logoutConfirm)
                    .font(theme.typography.font(size: 20, weight: .bold, relativeTo: .title3))
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func card(_ items: [SettingsItem], withLogout: Bool) -> some View {
        VStack(spacing: Spacing.xs) {
            ForEach(items) { item in
                row(item)
            }
            if withLogout, onLogout != nil {
                TKSettingsRow(
                    title: kit(KitStrings.Settings.logout),
                    icon: Image(tk: .logout),
                    role: .destructive,
                    accessory: .none
                ) { confirmingLogout = true }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, Spacing.sm)
        .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func row(_ item: SettingsItem) -> some View {
        if case .toggle = item.accessory {
            TKSettingsRow(title: item.title, icon: item.icon, role: item.role, accessory: item.accessory)
        } else {
            TKSettingsRow(title: item.title, icon: item.icon, role: item.role, accessory: item.accessory) {
                onSelect(item.id)
            }
        }
    }

    private func logOut() {
        confirmingLogout = false
        guard let onLogout else { return }
        isLoggingOut = true
        Task {
            await onLogout()
            isLoggingOut = false
        }
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}

public extension SettingsScreen where Header == EmptyView {
    init(
        title: Text? = nil,
        sections: [SettingsSection],
        onBack: (() -> Void)? = nil,
        onSelect: @escaping (String) -> Void,
        onLogout: (() async -> Void)? = nil
    ) {
        self.init(title: title, sections: sections, onBack: onBack, onSelect: onSelect, onLogout: onLogout) { EmptyView() }
    }
}
