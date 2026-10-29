import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanIcons
import TitanNavigation
import TitanPurchase

/// Figma "chats (roleplay & AI chatbot)": Roleplay and My Roleplay tabs, then a two-column grid
/// of scenario cards. Premium scenarios carry a crown and open "Premium Content" for free users.
struct ChatsScreen: View {
    enum Section: Hashable {
        case roleplay, mine
    }

    let roleplays: any RoleplayRepository
    let purchase: any PurchaseService
    let router: Router<AppRoute>

    @State private var section = Section.roleplay
    @State private var state: LoadState<[Roleplay]> = .idle
    @State private var isPremium = false
    @State private var lockedRoleplay: Roleplay?
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
                TKEmptyState(icon: Image(tk: .editSquare), title: "chats.mine.title", message: "chats.mine.message")
                    .frame(maxHeight: .infinity)
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
