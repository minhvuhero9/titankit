import SwiftUI
import TitanAuth
import TitanCore
import TitanDesignSystem
import TitanFeatures
import TitanLocalization
import TitanNavigation
import TitanNetworking
import TitanPush
import TitanPurchase
import TitanRemoteConfig
import TitanSpeech
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
    let remoteConfig: any RemoteConfigService
    let purchase: any PurchaseService
    let flow: AppFlow
    let learning: LearningStore
    let speech: any SpeechRecognizer
    let roleplays: any RoleplayRepository
    let phrasebook: any PhrasebookRepository
    let savedPhrases: SavedPhrases
    let activity: ActivityStore
    let reminder: StudyReminder
    /// One navigation stack per tab.
    let tabs: TabRouter<AppTab, AppRoute>
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
        auth: (any AuthService)? = nil,
        remoteConfig: (any RemoteConfigService)? = nil,
        purchase: (any PurchaseService)? = nil,
        courses: any CourseRepository = BundledCourseRepository(),
        roleplays: any RoleplayRepository = BundledRoleplayRepository(),
        phrasebook: any PhrasebookRepository = BundledPhrasebookRepository(),
        reminders: any ReminderScheduler = UserNotificationReminderScheduler(),
        speech: (any SpeechRecognizer)? = nil
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
        // Firebase Remote Config replaces the mock in phase 4.
        let remoteConfig = remoteConfig ?? AppContainer.launchArgumentConfig(ProcessInfo.processInfo.arguments)
        self.remoteConfig = remoteConfig
        self.purchase = purchase ?? StoreKitPurchaseService(config: AppConfig.purchase, logger: logger)
        let launchChecker = LaunchChecker(config: remoteConfig, appVersion: config.appVersion, storeURL: AppConfig.appStoreURL)
        flow = AppFlow(auth: auth, preferences: preferences, launchChecker: launchChecker, appVersion: config.appVersion)
        let learning = LearningStore(repository: courses, preferences: preferences)
        self.learning = learning
        self.speech = speech ?? AppleSpeechRecognizer()
        self.roleplays = roleplays
        self.phrasebook = phrasebook
        savedPhrases = SavedPhrases(preferences: preferences)
        let activity = ActivityStore(preferences: preferences)
        activity.chaptersDone = { learning.chaptersDone }
        self.activity = activity
        reminder = StudyReminder(scheduler: reminders, preferences: preferences)
        let tabs = TabRouter<AppTab, AppRoute>(initial: .home)
        self.tabs = tabs
        deepLinks = DeepLinkHandler(parser: DolingoDeepLinkParser()) { link in
            // Settings is the root of the Account tab.
            if link.route == .settings {
                tabs.selected = .account
            } else {
                tabs.open(link, in: .home)
            }
        }
    }

    /// The Home tab's stack, where deep links open.
    var router: Router<AppRoute> { tabs.router(for: .home) }

    /// The one place that turns a route into a screen. `router` is the stack the screen is in.
    @ViewBuilder
    func makeView(for route: AppRoute, in router: Router<AppRoute>) -> some View {
        switch route {
        case .catalog: TKCatalogView()
        case .settings: DolingoSettingsScreen(container: self, router: router, onBack: { router.pop() })
        case .appearance: DolingoAppearanceScreen(localization: localization) { [router] in router.pop() }
        case let .webPage(page): DolingoWebPage(page: page) { [router] in router.pop() }
        case .profile:
            ProfileScreen(auth: auth, onBack: { [router] in router.pop() },
                          onDeleteAccount: { [router] in router.push(.deleteAccount) })
        case .deleteAccount:
            DeleteAccountScreen(auth: auth, onBack: { [router] in router.pop() }) { [flow, router] in
                flow.didDeleteAccount()
                router.popToRoot()
            }
        case .paywall:
            DolingoPaywall(purchase: purchase) { [router] in router.dismiss() }
        case let .lesson(id):
            LessonScreen(learning: learning, speech: speech, activity: activity, lessonId: id) { [router] in router.dismiss() }
        case let .roleplay(roleplay):
            RoleplayDetailScreen(roleplay: roleplay, onBack: { [router] in router.pop() }) { [router] in
                router.push(.roleplayChat(roleplay))
            }
        case let .phrasePractice(category):
            PhrasePracticeScreen(category: category, saved: savedPhrases, speech: speech, activity: activity) { [router] in router.dismiss() }
        case .preferences:
            PreferencesScreen(container: self) { [router] in router.pop() }
        case .notifications:
            NotificationSettingsScreen(reminder: reminder) { [router] in router.pop() }
        case .security:
            SecurityScreen(auth: auth, onBack: { [router] in router.pop() },
                           onDeleteAccount: { [router] in router.push(.deleteAccount) })
        case .billing:
            BillingScreen(purchase: purchase, onBack: { [router] in router.pop() },
                          onUpgrade: { [router] in router.present(.paywall) })
        case .help:
            HelpScreen(appVersion: config.appVersion, onBack: { [router] in router.pop() },
                       onOpen: { [router] in router.push($0) })
        case .faq:
            FAQScreen { [router] in router.pop() }
        case .contactSupport:
            ContactSupportScreen { [router] in router.pop() }
        case .savedPhrases:
            SavedPhrasesScreen(saved: savedPhrases) { [router] in router.pop() }
        case let .roleplayChat(roleplay):
            RoleplayChatScreen(roleplay: roleplay, language: AppConfig.learningLanguage, speech: speech,
                               activity: activity) { [router] in
                router.popToRoot()
            }
        }
    }

    /// Until the real remote config exists, the blocking screens can be tried from Xcode:
    /// add `-maintenance` or `-forceUpdate` to the scheme's launch arguments.
    static func launchArgumentConfig(_ arguments: [String]) -> MockRemoteConfig {
        var values: [String: RemoteConfigRaw] = [:]
        if arguments.contains("-maintenance") {
            values[RemoteConfigKey<Bool>.maintenanceEnabled.name] = .bool(true)
        }
        if arguments.contains("-forceUpdate") {
            values[RemoteConfigKey<String>.minimumVersion.name] = .string("999.0.0")
        }
        return MockRemoteConfig(values: values)
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
            languageDefaults: UserDefaults(suiteName: "preview") ?? .standard,
            remoteConfig: MockRemoteConfig(),
            purchase: MockPurchaseService(),
            reminders: MockReminderScheduler(),
            speech: MockSpeechRecognizer(transcripts: ["hello"])
        )
    }

    var kitVersion: String { TitanCoreModule.version }
}
