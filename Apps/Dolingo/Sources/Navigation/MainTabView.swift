import SwiftUI
import TitanDesignSystem
import TitanFeatures
import TitanIcons
import TitanNavigation

/// The signed-in app: five tabs, each with its own navigation stack, and the Figma "Menu Bar".
struct MainTabView: View {
    let container: AppContainer
    @ObservedObject var tabs: TabRouter<AppTab, AppRoute>
    @ObservedObject var flow: AppFlow

    var body: some View {
        TabView(selection: $tabs.selected) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let router = tabs.router(for: tab)
                RouterView(router: router) {
                    root(for: tab, router: router)
                } destination: { route in
                    container.makeView(for: route, in: router)
                }
                .tag(tab)
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TKTabBar(selected: tabs.selected, items: Self.items) { tabs.select($0) }
        }
        .tkRequestReview(when: flow.shouldAskForReview) { flow.didAskForReview() }
        .task { await container.learning.load() }
    }

    @ViewBuilder
    private func root(for tab: AppTab, router: Router<AppRoute>) -> some View {
        switch tab {
        case .home:
            HomeScreen(learning: container.learning, purchase: container.purchase, router: router)
        case .chats:
            ChatsScreen(roleplays: container.roleplays, purchase: container.purchase, router: router)
        case .speak:
            ComingSoonTab(title: "tab.speak", icon: Image(tk: .voice))
        case .progress:
            ComingSoonTab(title: "tab.progress", icon: Image(tk: .graph))
        case .account:
            DolingoSettingsScreen(container: container, router: router)
        }
    }

    static var items: [TKTabItem<AppTab>] {
        [
            TKTabItem(.home, title: "tab.home", icon: .home),
            TKTabItem(.chats, title: "tab.chats", icon: .chat),
            TKTabItem(.speak, title: "tab.speak", icon: .voice),
            TKTabItem(.progress, title: "tab.progress", icon: .graph),
            TKTabItem(.account, title: "tab.account", icon: .profile),
        ]
    }
}

/// Holds a tab's place until its screens are built.
private struct ComingSoonTab: View {
    let title: LocalizedStringKey
    let icon: Image
    @Environment(\.theme) private var theme

    var body: some View {
        TKEmptyState(icon: icon, title: title, message: "tab.comingSoon")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
            .tkNavigationBar(title)
    }
}
