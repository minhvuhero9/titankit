import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanIcons
import TitanLocalization
import TitanPurchase
import TitanStorage
import UIKit

/// A rounded card of settings rows, as on the Figma settings sub-screens.
private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.xs) { content }
            .padding(.horizontal, 20)
            .padding(.vertical, Spacing.sm)
            .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A scrolling settings page with a back arrow.
private struct SettingsPage<Content: View>: View {
    let title: LocalizedStringKey
    let onBack: () -> Void
    @ViewBuilder let content: Content
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) { content }
                .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title, onBack: onBack)
    }
}

// MARK: - Notification (Figma 96)

/// The daily study reminder: on/off and the time, scheduled on the device.
struct NotificationSettingsScreen: View {
    @ObservedObject var reminder: StudyReminder
    let onBack: () -> Void

    @State private var pickingTime = false
    @State private var draft = Date()
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @Environment(\.theme) private var theme

    var body: some View {
        SettingsPage(title: "settings.notification", onBack: onBack) {
            SettingsCard {
                TKSettingsRow("settings.reminder.daily", accessory: .toggle(enabledBinding))
                TKSettingsRow("settings.reminder.time", accessory: .value(Text(verbatim: timeText))) {
                    draft = Calendar.current.date(bySettingHour: reminder.settings.hour, minute: reminder.settings.minute,
                                                  second: 0, of: Date()) ?? Date()
                    pickingTime = true
                }
            }
            if reminder.isDenied {
                VStack(spacing: Spacing.sm) {
                    Text("settings.reminder.denied")
                        .tkTextStyle(.callout)
                        .foregroundStyle(theme.colors.textSecondary.color)
                        .multilineTextAlignment(.center)
                    TKButton("settings.openSystemSettings", style: .light, size: .small, shape: .pill) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
            }
            Text("settings.reminder.note")
                .tkTextStyle(.caption)
                .foregroundStyle(theme.colors.textSecondary.color)
                .multilineTextAlignment(.center)
        }
        .tkSheet(isPresented: $pickingTime) {
            TKSheet(
                title: Text("settings.reminder.time"),
                primary: TKModalAction(title: Text.kit(KitStrings.ok, locale: locale)) {
                    pickingTime = false
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: draft)
                    Task { await reminder.setTime(hour: parts.hour ?? 20, minute: parts.minute ?? 0, locale: locale) }
                },
                secondary: TKModalAction(title: Text.kit(KitStrings.cancel, locale: locale)) { pickingTime = false }
            ) {
                DatePicker(selection: $draft, displayedComponents: .hourAndMinute) { EmptyView() }
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            reminder.settings.isOn
        } set: { isOn in
            Task { await reminder.setEnabled(isOn, locale: locale) }
        }
    }

    private var timeText: String {
        let date = Calendar.current.date(bySettingHour: reminder.settings.hour, minute: reminder.settings.minute,
                                         second: 0, of: Date()) ?? Date()
        return date.formatted(.dateTime.hour().minute().locale(locale))
    }
}

// MARK: - Preferences (Figma 94)

/// Restart all progress and clear the cache.
struct PreferencesScreen: View {
    let container: AppContainer
    let onBack: () -> Void

    @State private var confirmingRestart = false
    @State private var toast: TKToast?
    @Environment(\.locale) private var locale
    @Environment(\.theme) private var theme

    var body: some View {
        SettingsPage(title: "settings.preferences", onBack: onBack) {
            SettingsCard {
                TKSettingsRow("settings.restart", accessory: .chevron) { confirmingRestart = true }
                TKSettingsRow("settings.clearCache", accessory: .chevron) {
                    Task {
                        await container.dataCache.clear()
                        container.imageCache.clearMemory()
                        toast = TKToast(KitStrings.string("settings.clearCache.done", locale: locale), style: .success)
                    }
                }
            }
        }
        .tkToast($toast)
        .tkSheet(isPresented: $confirmingRestart) {
            TKSheet(
                title: Text("settings.restart"),
                titleColor: theme.colors.feedbackError.color,
                primary: TKModalAction(title: Text("settings.restart.confirm")) {
                    confirmingRestart = false
                    container.learning.reset()
                    container.activity.reset()
                    toast = TKToast(KitStrings.string("settings.restart.done", locale: locale), style: .success)
                },
                secondary: TKModalAction(title: Text.kit(KitStrings.cancel, locale: locale)) { confirmingRestart = false }
            ) {
                Text("settings.restart.message")
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Account & Security (Figma 97)

/// Change password with a code sent by email, and delete the account.
struct SecurityScreen: View {
    let auth: any AuthService
    let onBack: () -> Void
    let onChangePassword: (_ email: String) -> Void
    let onDeleteAccount: () -> Void

    @State private var email: String?
    @Environment(\.locale) private var locale

    var body: some View {
        SettingsPage(title: "settings.security", onBack: onBack) {
            SettingsCard {
                if let email {
                    TKSettingsRow("settings.changePassword", accessory: .chevron) {
                        onChangePassword(email)
                    }
                }
                TKSettingsRow(title: Text.kit(KitStrings.DeleteAccount.title, locale: locale), role: .destructive,
                              action: onDeleteAccount)
            }
        }
        .task {
            let user = await auth.currentUser()
            email = user?.provider == .email ? user?.email : nil
        }
    }
}

// MARK: - Billing & Subscriptions (Figma 98)

/// The plan the learner has, how to manage or restore it, or an upgrade button.
struct BillingScreen: View {
    let purchase: any PurchaseService
    let onBack: () -> Void
    let onUpgrade: () -> Void

    @State private var entitlements = Entitlements.none
    @State private var isRestoring = false
    @State private var toast: TKToast?
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @Environment(\.theme) private var theme

    var body: some View {
        SettingsPage(title: "settings.billing", onBack: onBack) {
            VStack(spacing: Spacing.sm) {
                Text(LocalizedStringKey(entitlements.isPremium ? "billing.premium" : "billing.free"))
                    .tkTextStyle(.title2)
                    .foregroundStyle(theme.colors.textPrimary.color)
                if entitlements.isPremium, let expiry = entitlements.expiresAt {
                    Text("billing.renews \(expiry.formatted(.dateTime.day().month(.wide).year().locale(locale)))")
                        .tkTextStyle(.callout)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                Text(LocalizedStringKey(entitlements.isPremium ? "billing.premium.message" : "billing.free.message"))
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .tkOutlinedCard(isSelected: entitlements.isPremium)
            if entitlements.isPremium {
                TKButton("billing.manage", style: .light, shape: .pill) { openURL(AppConfig.manageSubscriptionsURL) }
            } else {
                TKButton("billing.upgrade", shape: .pill, action: onUpgrade)
            }
            TKButton(Text.kit(KitStrings.Paywall.restore, locale: locale), style: .outline, size: .small, shape: .pill,
                     isLoading: isRestoring) {
                Task { await restore() }
            }
        }
        .tkToast($toast)
        .task {
            for await value in purchase.entitlementStream {
                entitlements = value
            }
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            let restored = try await purchase.restore()
            let key = restored.isPremium ? "billing.restored" : KitStrings.Paywall.nothingToRestore
            toast = TKToast(KitStrings.string(key, locale: locale), style: restored.isPremium ? .success : .info)
        } catch {
            toast = TKToast(KitStrings.string(error.messageKey, locale: locale), style: .error)
        }
    }
}

// MARK: - Help & Support (Figma 107)

struct HelpScreen: View {
    let appVersion: String
    let onBack: () -> Void
    let onOpen: (AppRoute) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsPage(title: "settings.help", onBack: onBack) {
            SettingsCard {
                TKSettingsRow("help.faq") { onOpen(.faq) }
                TKSettingsRow("help.contact") { onOpen(.contactSupport) }
                TKSettingsRow(title: Text.kit(KitStrings.Settings.privacy, locale: locale)) { onOpen(.webPage(.privacy)) }
                TKSettingsRow(title: Text.kit(KitStrings.Settings.terms, locale: locale)) { onOpen(.webPage(.terms)) }
                TKSettingsRow(title: Text.kit(KitStrings.Settings.rateApp, locale: locale)) { openURL(AppConfig.writeReviewURL) }
                TKSettingsRow("help.website") { openURL(AppConfig.websiteURL) }
                TKSettingsRow("help.version", accessory: .value(Text(verbatim: appVersion)))
            }
        }
    }
}

// MARK: - FAQ (Figma 108)

/// Questions grouped by topic, with search; tap a question to open its answer.
struct FAQScreen: View {
    enum Topic: String, CaseIterable, Hashable {
        case general, account, premium, learning
    }

    struct Entry: Identifiable {
        let id: String
        let topic: Topic
    }

    static let entries: [Entry] = [
        Entry(id: "what", topic: .general), Entry(id: "free", topic: .general),
        Entry(id: "offline", topic: .general), Entry(id: "data", topic: .account),
        Entry(id: "delete", topic: .account), Entry(id: "password", topic: .account),
        Entry(id: "premium", topic: .premium), Entry(id: "cancel", topic: .premium),
        Entry(id: "restore", topic: .premium), Entry(id: "microphone", topic: .learning),
        Entry(id: "score", topic: .learning), Entry(id: "streak", topic: .learning),
    ]

    let onBack: () -> Void

    @State private var topic = Topic.general
    @State private var search = ""
    @State private var open: Set<String> = []
    @Environment(\.locale) private var locale
    @Environment(\.theme) private var theme

    var body: some View {
        SettingsPage(title: "help.faq", onBack: onBack) {
            TKSearchField(text: $search, prompt: "help.faq.search")
            if search.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(Topic.allCases, id: \.self) { item in
                            TKChip(LocalizedStringKey("faq.topic.\(item.rawValue)"), isSelected: item == topic, size: .small) {
                                topic = item
                            }
                        }
                    }
                }
            }
            ForEach(visibleEntries) { entry in
                answerCard(entry)
            }
            if visibleEntries.isEmpty {
                TKEmptyState(icon: Image(tk: .search), title: "help.faq.none")
            }
        }
    }

    /// The selected topic's questions, or every match for the search.
    private var visibleEntries: [Entry] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return Self.entries.filter { $0.topic == topic } }
        return Self.entries.filter { entry in
            [question(entry), answer(entry)].contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    private func answerCard(_ entry: Entry) -> some View {
        let isOpen = open.contains(entry.id) || !search.isEmpty
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                withAnimation {
                    if open.contains(entry.id) { open.remove(entry.id) } else { open.insert(entry.id) }
                }
            } label: {
                HStack {
                    Text(verbatim: question(entry))
                        .tkTextStyle(.headline)
                        .foregroundStyle(theme.colors.textPrimary.color)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
            }
            .buttonStyle(.plain)
            if isOpen {
                TKDivider()
                Text(verbatim: answer(entry))
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .tkOutlinedCard()
    }

    private func question(_ entry: Entry) -> String {
        KitStrings.string("faq.\(entry.id).q", locale: locale)
    }

    private func answer(_ entry: Entry) -> String {
        KitStrings.string("faq.\(entry.id).a", locale: locale)
    }
}

// MARK: - Contact Support (Figma 109)

struct ContactSupportScreen: View {
    let onBack: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsPage(title: "help.contact", onBack: onBack) {
            SettingsCard {
                TKSettingsRow("contact.email", icon: Image(tk: .message), accessory: .value(Text(verbatim: AppConfig.supportEmail))) {
                    if let url = URL(string: "mailto:\(AppConfig.supportEmail)") { openURL(url) }
                }
                TKSettingsRow("help.website", icon: Image(tk: .discovery)) { openURL(AppConfig.websiteURL) }
            }
        }
    }
}

// MARK: - Invite friends

/// A small sheet with the share sheet button, for the "Invite your friends" row.
struct InviteSheet: View {
    let onClose: () -> Void
    @Environment(\.locale) private var locale
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(verbatim: "🎁").font(.system(size: 64))
            Text("invite.title")
                .tkTextStyle(.title2)
                .foregroundStyle(theme.colors.textPrimary.color)
            Text("invite.message")
                .tkTextStyle(.body)
                .foregroundStyle(theme.colors.textSecondary.color)
                .multilineTextAlignment(.center)
            ShareLink(item: AppConfig.appStoreURL, message: Text(verbatim: KitStrings.string("invite.share", locale: locale))) {
                Label("invite.action", systemImage: "square.and.arrow.up")
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.actionOnPrimary.color)
                    .frame(maxWidth: .infinity, minHeight: TKButton.Size.large.height)
                    .background(theme.colors.actionPrimary.color, in: Capsule())
            }
            TKButton(Text.kit(KitStrings.cancel, locale: locale), style: .light, shape: .pill, action: onClose)
        }
        .padding(Spacing.lg)
        .presentationDetents([.medium])
    }
}
