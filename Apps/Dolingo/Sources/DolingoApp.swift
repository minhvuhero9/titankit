import SwiftUI

@main
struct DolingoApp: App {
    @StateObject private var container = AppContainer(config: .current)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
        }
    }
}
