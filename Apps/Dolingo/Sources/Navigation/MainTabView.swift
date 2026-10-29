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
    @ObservedObject var activity: ActivityStore

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
        .overlay {
            if let celebration = activity.celebrations.first {
                CelebrationView(celebration: celebration) {
                    withAnimation { activity.dismissCelebration() }
                }
                .id(celebration.id)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: activity.celebrations.first?.id)
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
            SpeakScreen(phrasebook: container.phrasebook, purchase: container.purchase, router: router)
        case .progress:
            ProgressScreen(activity: container.activity, learning: container.learning, phrasebook: container.phrasebook)
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
