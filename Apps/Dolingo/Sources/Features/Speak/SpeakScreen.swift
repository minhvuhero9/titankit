import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanIcons
import TitanLocalization
import TitanNavigation
import TitanPurchase

/// Figma "speak (phrasebook)": the phrase topics, with a crown on premium ones, and a bookmark
/// button for the saved phrases.
struct SpeakScreen: View {
    let phrasebook: any PhrasebookRepository
    let purchase: any PurchaseService
    let router: Router<AppRoute>

    @State private var state: LoadState<[PhraseCategory]> = .idle
    @State private var isPremium = false
    @State private var showsPremium = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        TKAsyncContent(state, retry: { Task { await load() } }) { categories in
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(categories) { category in
                        row(category)
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar("tab.speak") {
            TKNavBarButton(Image(tk: .bookmark), accessibilityLabel: KitStrings.string("speak.saved", locale: locale)) {
                router.push(.savedPhrases)
            }
        }
        .task { await load() }
        .task {
            for await entitlements in purchase.entitlementStream {
                isPremium = entitlements.isPremium
            }
        }
        .tkModal(isPresented: $showsPremium) {
            TKModal(
                title: Text("chats.premium.title"),
                message: Text("chats.premium.message"),
                primary: TKModalAction(title: Text("chats.premium.upgrade")) {
                    showsPremium = false
                    router.present(.paywall)
                },
                secondary: TKModalAction(title: Text("chats.premium.later")) { showsPremium = false }
            ) {
                Text(verbatim: "👑")
                    .font(.system(size: 64))
                    .frame(width: 120, height: 120)
                    .background(theme.colors.feedbackWarning.color.opacity(0.25), in: Circle())
            }
        }
    }

    private func row(_ category: PhraseCategory) -> some View {
        let isLocked = category.isPremium && !isPremium
        return TKOptionCard(title: Text(verbatim: category.title.localized(languageCode))) {
            Text(verbatim: category.emoji)
                .font(.system(size: 32))
                .accessibilityHidden(true)
        } trailing: {
            if isLocked {
                Text(verbatim: "👑").accessibilityLabel(Text("chats.premium.title"))
            }
        } action: {
            if isLocked {
                showsPremium = true
            } else {
                router.present(.phrasePractice(category), fullScreen: true)
            }
        }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await phrasebook.categories(language: AppConfig.learningLanguage))
        } catch {
            state = .failed(error)
        }
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "vi"
    }
}
