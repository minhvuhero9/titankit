import SwiftUI
import TitanCore
import TitanDesignSystem

@main
struct DolingoApp: App {
    @StateObject private var container = AppContainer(config: .current)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environment(\.container, container)
                .environment(\.logger, container.logger)
                .environment(\.imageCache, container.imageCache)
                .titanTheme(DolingoTheme.theme)
        }
    }
}
