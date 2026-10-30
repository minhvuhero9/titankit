import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanIcons
import TitanNavigation
import TitanPurchase

/// Figma "chats (roleplay & AI chatbot)": Roleplay and My Roleplay tabs, then a two-column grid
/// of scenario cards. Premium scenarios carry a crown and open "Premium Content" for free users.
/// The robot button opens "Chat with Dolingo"; "+" creates a roleplay with AI (Figma 60–67), which
/// then lives under My Roleplay with Edit and Delete in its ⋮ menu.
struct ChatsScreen: View {
    enum Section: Hashable {
        case roleplay, mine
    }

    let roleplays: any RoleplayRepository
    let purchase: any PurchaseService
    @ObservedObject var mine: MyRoleplays
    let router: Router<AppRoute>

    @State private var section = Section.roleplay
    @State private var state: LoadState<[Roleplay]> = .idle
    @State private var isPremium = false
    @State private var lockedRoleplay: Roleplay?
    @State private var offersTrial = false
    @State private var deleting: CustomRoleplay?
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.md) {
            TKSegmentedTabs(selection: $section, options: [
                TKOption(.roleplay, title: "chats.roleplay"),
                TKOption(.mine, title: "chats.mine"),
            ])
            .padding(.horizontal, Spacing.lg)
            switch section {
            case .roleplay:
                TKAsyncContent(state, isEmpty: \.isEmpty, empty: TKEmptyState(
                    icon: Image(tk: .chat), title: "chats.empty.title", message: "chats.empty.message"
                ), retry: { Task { await load() } }) { roleplays in
                    grid(roleplays)
                }
            case .mine:
                if mine.roleplays.isEmpty {
                    TKEmptyState(icon: Image(tk: .editSquare), title: "chats.mine.title", message: "chats.mine.message",
                                 actionTitle: "chats.create") { create() }
                        .frame(maxHeight: .infinity)
                } else {
                    myGrid
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: Spacing.md) {
                floatingButton(Image(tk: TKSymbol.botSparkleFilled), label: "tutor.title") {
                    router.present(.tutorChat, fullScreen: true)
                }
                floatingButton(Image(tk: .plus), label: "chats.create") { create() }
            }
            .padding(Spacing.lg)
        }
        .tkSheet(isPresented: $offersTrial) {
            TKSheet(
                title: Text("chats.create"),
                primary: TKModalAction(title: Text("chats.create")) {
                    offersTrial = false
                    router.push(.createRoleplay(editing: nil))
                },
                secondary: TKModalAction(title: Text("chats.premium.upgrade")) {
                    offersTrial = false
                    router.present(.paywall)
                }
            ) {
                VStack(spacing: Spacing.md) {
                    Text(verbatim: "👑")
                        .font(.system(size: 48))
                        .frame(width: 96, height: 96)
                        .background(theme.colors.actionPrimary.color, in: Circle())
                    Text("chats.create.trials \(mine.trialsLeft)")
                        .tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textPrimary.color)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .tkSheet(isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            TKSheet(
                title: Text("chats.delete"),
                titleColor: theme.colors.feedbackError.color,
                primary: TKModalAction(title: Text("chats.delete.confirm")) {
                    if let deleting { mine.delete(id: deleting.id) }
                    deleting = nil
                },
                secondary: TKModalAction(title: Text("chats.delete.cancel")) { deleting = nil }
            ) {
                VStack(spacing: Spacing.xs) {
                    Text("chats.delete.title")
                        .tkTextStyle(.title3)
                        .foregroundStyle(theme.colors.textPrimary.color)
                    Text("chats.delete.message")
                        .tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar("tab.chats")
        .task { await load() }
        .task {
            for await entitlements in purchase.entitlementStream {
                isPremium = entitlements.isPremium
            }
        }
        .tkModal(isPresented: Binding(get: { lockedRoleplay != nil }, set: { if !$0 { lockedRoleplay = nil } })) {
            TKModal(
                title: Text("chats.premium.title"),
                message: Text("chats.premium.message"),
                primary: TKModalAction(title: Text("chats.premium.upgrade")) {
                    lockedRoleplay = nil
                    router.present(.paywall)
                },
                secondary: TKModalAction(title: Text("chats.premium.later")) { lockedRoleplay = nil }
            ) {
                Text(verbatim: "👑")
                    .font(.system(size: 64))
                    .frame(width: 120, height: 120)
                    .background(theme.colors.feedbackWarning.color.opacity(0.25), in: Circle())
            }
        }
    }

    private func grid(_ roleplays: [Roleplay]) -> some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)],
                      spacing: Spacing.md) {
                ForEach(roleplays) { roleplay in
                    RoleplayCard(roleplay: roleplay, isLocked: roleplay.isPremium && !isPremium) {
                        if roleplay.isPremium && !isPremium {
                            lockedRoleplay = roleplay
                        } else {
                            router.push(.roleplay(roleplay))
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }

    private var myGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)],
                      spacing: Spacing.md) {
                ForEach(mine.roleplays) { roleplay in
                    MyRoleplayCard(
                        roleplay: roleplay,
                        onOpen: { router.push(.aiRoleplayChat(roleplay)) },
                        onEdit: { router.push(.createRoleplay(editing: roleplay)) },
                        onDelete: { deleting = roleplay }
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            // Room for the floating buttons.
            .padding(.bottom, 96)
        }
    }

    private func floatingButton(_ icon: Image, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .frame(width: 56, height: 56)
                .background(theme.gradientPrimary.linearGradient, in: Circle())
                .shadow(color: theme.colors.actionPrimary.color.opacity(0.35), radius: 12, y: 6)
        }
        .accessibilityLabel(Text(label))
    }

    /// Premium learners go straight to the form; free ones see how many trials are left, or the
    /// paywall once they are used up.
    private func create() {
        if isPremium {
            router.push(.createRoleplay(editing: nil))
        } else if mine.trialsLeft > 0 {
            offersTrial = true
        } else {
            router.present(.paywall)
        }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await roleplays.roleplays(language: AppConfig.learningLanguage))
        } catch {
            state = .failed(error)
        }
    }
}

/// Figma roleplay card: the title top left, a big emoji bottom right, a crown when locked.
private struct RoleplayCard: View {
    let roleplay: Roleplay
    let isLocked: Bool
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: roleplay.title.localized(locale.language.languageCode?.identifier ?? "vi"))
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: Spacing.sm)
                HStack(alignment: .bottom) {
                    if isLocked {
                        Text(verbatim: "👑")
                            .font(.system(size: 18))
                            .accessibilityLabel(Text("chats.premium.title"))
                    }
                    Spacer()
                    Text(verbatim: roleplay.emoji)
                        .font(.system(size: 56))
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .frame(height: 160)
            .tkOutlinedCard()
        }
        .buttonStyle(.plain)
    }
}

/// Figma "my roleplay" card: like the scenario cards, with a ⋮ menu for Edit and Delete.
private struct MyRoleplayCard: View {
    let roleplay: CustomRoleplay
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: roleplay.title)
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: Spacing.sm)
                HStack(alignment: .bottom) {
                    // Keeps the space under the ⋮ menu, which sits on top of the card.
                    Color.clear.frame(width: 32, height: 32)
                    Spacer()
                    Text(verbatim: roleplay.emoji)
                        .font(.system(size: 56))
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.md)
            .frame(height: 160)
            .tkOutlinedCard()
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomLeading) {
            Menu {
                Button(action: onEdit) {
                    Label("chats.edit", systemImage: "square.and.pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("chats.delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .frame(width: 44, height: 44)
            }
            .padding(Spacing.xs)
            .accessibilityLabel(Text("tutor.more"))
        }
    }
}
