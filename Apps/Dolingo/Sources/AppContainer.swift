import SwiftUI
import TitanCore

/// Composition Root: the one place that builds services and picks adapters.
/// Phase 0 only holds the config; services are added from phase 1 on.
@MainActor
final class AppContainer: ObservableObject {
    let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    var kitVersion: String { TitanCoreModule.version }
}
