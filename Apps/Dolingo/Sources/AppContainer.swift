import SwiftUI
import TitanAuth
import TitanCore
import TitanDesignSystem
import TitanLocalization
import TitanNavigation
import TitanNetworking
import TitanStorage

/// Composition Root: the one place that builds services and picks adapters.
@MainActor
final class AppContainer: ObservableObject, DependencyContainer {
    let config: AppConfig
    let logger: any Logging
    let api: any APIClient
    let secureStore: any SecureStore
    let dataCache: any DataCache
    let imageCache: any ImageCache
    let preferences: Preferences
    let networkMonitor: NetworkMonitor
    let localization: LocalizationService
    let auth: any AuthService
    let flow: AppFlow
    let router: Router<AppRoute>
    let deepLinks: DeepLinkHandler<DolingoDeepLinkParser>

    init(
        config: AppConfig,
        api: (any APIClient)? = nil,
        secureStore: (any SecureStore)? = nil,
        dataCache: (any DataCache)? = nil,
        imageCache: (any ImageCache)? = nil,
        preferences: Preferences = Preferences(),
        networkMonitor: NetworkMonitor? = nil,
        languageDefaults: UserDefaults = .standard,
        auth: (any AuthService)? = nil
    ) {
        let logger = OSLogger(subsystem: "com.titanstudio.dolingo", minLevel: config.environment.defaultLogLevel)
        self.config = config
        self.logger = logger
        self.api = api ?? DefaultAPIClient(
            baseURL: config.apiBaseURL,
            interceptors: [
                RetryInterceptor(),
                LoggingInterceptor(logger: logger, logBodies: !config.environment.isProduction),
            ]
        )
        self.secureStore = secureStore ?? KeychainStore(service: "com.titanstudio.dolingo")
        self.dataCache = dataCache ?? FileCache()
        self.imageCache = imageCache ?? URLSessionImageCache.shared
        self.preferences = preferences
        self.networkMonitor = networkMonitor ?? NetworkMonitor()
        localization = LocalizationService(
            supported: AppConfig.languages,
            defaultLanguage: AppConfig.defaultLanguage,
            defaults: languageDefaults
        )
        // Firebase adapter replaces the mock in phase 4.
        let auth = auth ?? MockAuthService(delay: .milliseconds(600))
        self.auth = auth
        flow = AppFlow(auth: auth, preferences: preferences)
        let router = Router<AppRoute>()
        self.router = router
        deepLinks = DeepLinkHandler(parser: DolingoDeepLinkParser()) { link in
            router.open(link)
        }
    }

    /// The one place that turns a route into a screen.
    @ViewBuilder
    func makeView(for route: AppRoute) -> some View {
        switch route {
        case .catalog: TKCatalogView()
        case .settings: DolingoSettingsScreen(container: self)
        case .appearance: DolingoAppearanceScreen(localization: localization) { [router] in router.pop() }
        case let .webPage(page): DolingoWebPage(page: page) { [router] in router.pop() }
        }
    }

    /// Container for tests and previews: no network, no Keychain, nothing written to disk.
    static func preview(environment: AppEnvironment = .dev) -> AppContainer {
        AppContainer(
            config: AppConfig(environment: environment, apiBaseURL: URL(string: "https://api-dev.example.com")!),
            api: MockAPIClient(),
            secureStore: InMemorySecureStore(),
            dataCache: InMemoryDataCache(),
            imageCache: MockImageCache(),
            preferences: Preferences(defaults: UserDefaults(suiteName: "preview") ?? .standard),
            networkMonitor: NetworkMonitor(startMonitoring: false),
            languageDefaults: UserDefaults(suiteName: "preview") ?? .standard
        )
    }

    var kitVersion: String { TitanCoreModule.version }
}
