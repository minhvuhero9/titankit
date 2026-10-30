import SwiftUI
import TitanAI
import TitanAnalytics
import TitanAuth
import TitanCore
import TitanDesignSystem
#if !PERSONAL_TEAM
import TitanFirebaseAnalytics
#endif
import TitanFirebaseAuth
import TitanFirebaseCore
import TitanFirebaseRemoteConfig
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
    /// True when Resources/Firebase/GoogleService-Info-<Env>.plist is in the build: auth,
    /// remote config, analytics and crash reports then use Firebase instead of the mocks.
    let usesFirebase: Bool
    let analytics: any AnalyticsService
    let crash: any CrashService
    let dataSharing: DataSharingStore
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
    let tutorChat: TutorChat
    let roleplayAI: any RoleplayAI
    let myRoleplays: MyRoleplays
    let practice: PracticeSettingsStore
    /// The learner's name and level, for the AI.
    let learner: @MainActor () async -> ChatLearner
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
        speech: (any SpeechRecognizer)? = nil,
        chat: (any ChatService)? = nil,
        analytics: (any AnalyticsService)? = nil,
        roleplayAI: (any RoleplayAI)? = nil
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
        let usesFirebase = FirebaseBootstrap.configure(plistName: Self.firebasePlistName(config.environment))
        self.usesFirebase = usesFirebase
        let auth = auth ?? (usesFirebase ? FirebaseAuthService() : MockAuthService(delay: .milliseconds(600)))
        self.auth = auth
        let arguments = ProcessInfo.processInfo.arguments
        let remoteConfig = remoteConfig ?? (usesFirebase && !Self.forcesBlockingScreen(arguments)
            ? FirebaseRemoteConfigService(minimumFetchInterval: config.environment == .dev ? 0 : 3600)
            : AppContainer.launchArgumentConfig(arguments))
        self.remoteConfig = remoteConfig
        var trackers: [any AnalyticsService] = []
        #if !PERSONAL_TEAM
        if usesFirebase { trackers.append(FirebaseAnalyticsService()) }
        #endif
        if !config.environment.isProduction { trackers.append(ConsoleAnalyticsService(logger: logger)) }
        let analytics = analytics ?? CompositeAnalyticsService(trackers)
        self.analytics = analytics
        #if PERSONAL_TEAM
        let crash: any CrashService = NoOpAnalyticsService()
        #else
        let crash: any CrashService = usesFirebase ? CrashlyticsService() : NoOpAnalyticsService()
        #endif
        self.crash = crash
        dataSharing = DataSharingStore(preferences: preferences, analytics: analytics, crash: crash)
        self.purchase = purchase ?? StoreKitPurchaseService(config: AppConfig.purchase, logger: logger)
        let launchChecker = LaunchChecker(config: remoteConfig, appVersion: config.appVersion, storeURL: AppConfig.appStoreURL)
        let socialSignIn: SocialSignIn? = usesFirebase ? AppContainer.socialSignIn : nil
        let flow = AppFlow(auth: auth, preferences: preferences, launchChecker: launchChecker,
                           appVersion: config.appVersion, analytics: analytics, socialSignIn: socialSignIn)
        self.flow = flow
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
        let learner: @MainActor () async -> ChatLearner = {
            let user = await auth.currentUser()
            return ChatLearner(name: user?.displayName,
                               level: flow.surveyAnswers[DolingoSurvey.Step.level]?.optionIds.first)
        }
        self.learner = learner
        // With Firebase the AI server knows who is calling from the sign-in token.
        var aiToken: AITokenProvider?
        if usesFirebase {
            aiToken = { @Sendable [auth] forceRefresh in
                try? await auth.idToken(forceRefresh: forceRefresh)
            }
        }
        tutorChat = TutorChat(service: chat ?? AppContainer.chatService(config: config, token: aiToken),
                              preferences: preferences, learner: learner)
        self.roleplayAI = roleplayAI ?? AppContainer.roleplayAI(config: config, token: aiToken)
        myRoleplays = MyRoleplays(preferences: preferences)
        practice = PracticeSettingsStore(preferences: preferences)
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
            // Figma keeps "Delete Account" on Account & Security, not on Personal Info.
            ProfileScreen(auth: auth, onBack: { [router] in router.pop() })
        case .deleteAccount:
            DeleteAccountScreen(auth: auth, onBack: { [router] in router.pop() }) { [flow, router] in
                flow.didDeleteAccount()
                router.popToRoot()
            }
        case .paywall:
            DolingoPaywall(purchase: purchase) { [router] in router.dismiss() }
        case let .lesson(id):
            LessonScreen(learning: learning, speech: speech, activity: activity, practice: practice, lessonId: id) { [router] in router.dismiss() }
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
                           onChangePassword: { [router] in router.push(.changePassword(email: $0)) },
                           onLinkedAccounts: { [router] in router.push(.linkedAccounts) },
                           onDeleteAccount: { [router] in router.push(.deleteAccount) })
        case .linkedAccounts:
            LinkedAccountsScreen(
                auth: auth,
                options: [
                    LinkedAccountOption(.google, icon: Image("SocialGoogle"), name: "Google"),
                    LinkedAccountOption(.apple, icon: Image("SocialApple"), name: "Apple"),
                ],
                credential: linkCredential,
                onBack: { [router] in router.pop() }
            )
        case .dataAnalytics:
            DataAnalyticsScreen(store: dataSharing) { [router] in router.pop() }
        case let .changePassword(email):
            PasswordResetScreen(auth: auth, email: email, sendsLink: usesFirebase,
                                onExit: { [router] in router.pop() }) { [router] _ in
                router.pop()
            }
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
        case .tutorChat:
            TutorChatScreen(chat: tutorChat) { [router] in router.dismiss() }
        case let .createRoleplay(editing):
            CreateRoleplayScreen(
                viewModel: CreateRoleplayViewModel(editing: editing, ai: self.roleplayAI, learner: self.learner),
                onBack: { [router] in router.pop() }
            ) { [myRoleplays, router] roleplay in
                myRoleplays.save(roleplay)
                if editing == nil, !router.path.isEmpty {
                    // A new roleplay starts right away, in place of the form.
                    router.path[router.path.count - 1] = .aiRoleplayChat(roleplay)
                } else {
                    router.pop()
                }
            }
        case let .aiRoleplayChat(roleplay):
            AIRoleplayChatScreen(
                viewModel: AIRoleplayViewModel(roleplay: roleplay, language: AppConfig.learningLanguage,
                                               ai: self.roleplayAI, speech: self.speech, activity: self.activity,
                                               learner: self.learner),
                activity: activity,
                practice: practice
            ) { [router] in router.pop() }
        case .savedPhrases:
            SavedPhrasesScreen(saved: savedPhrases) { [router] in router.pop() }
        case let .roleplayChat(roleplay):
            RoleplayChatScreen(roleplay: roleplay, language: AppConfig.learningLanguage, speech: speech,
                               activity: activity, practice: practice) { [router] in
                router.popToRoot()
            }
        }
    }

    /// The AI server when it is configured, otherwise local answers that say so.
    static func chatService(config: AppConfig, token: AITokenProvider? = nil) -> any ChatService {
        if let url = config.aiBaseURL, token != nil || !config.aiClientKey.isEmpty {
            return RemoteChatService(baseURL: url, clientKey: config.aiClientKey, token: token)
        }
        return MockChatService { _ in
            "I'm not connected yet: the Dolingo AI server isn't set up in this build. "
                + "Once it is, I'll answer your questions about English here."
        }
    }

    /// The AI server's roleplay calls when it is configured, otherwise a canned pizza order.
    static func roleplayAI(config: AppConfig, token: AITokenProvider? = nil) -> any RoleplayAI {
        if let url = config.aiBaseURL, token != nil || !config.aiClientKey.isEmpty {
            return RemoteRoleplayAI(client: AIServerClient(baseURL: url, clientKey: config.aiClientKey, token: token))
        }
        return MockRoleplayAI(delay: .milliseconds(800))
    }

    /// One Firebase project per environment: GoogleService-Info-Dev, -Staging, -Prod.
    nonisolated static func firebasePlistName(_ environment: AppEnvironment) -> String {
        "GoogleService-Info-\(environment.rawValue.prefix(1).uppercased())\(environment.rawValue.dropFirst())"
    }

    /// The social buttons of the sign-in screen: Apple and Google with Firebase. Facebook needs
    /// its own SDK and app, so it only appears without Firebase, where every button is a guest.
    var socialProviders: [AuthProvider] {
        usesFirebase ? [.google, .apple] : [.google, .apple, .facebook]
    }

    /// Apple's or Google's sheet with Firebase; made-up tokens on the mocks, so linking can be
    /// tried without accounts.
    var linkCredential: CredentialRequest {
        usesFirebase ? AppContainer.socialSignIn : AppContainer.mockCredential
    }

    private static func mockCredential(_ provider: AuthProvider) async throws(TitanError) -> SignInMethod {
        switch provider {
        case .apple: .apple(idToken: "mock", rawNonce: "mock", fullName: nil)
        default: .google(idToken: "mock", accessToken: "mock")
        }
    }

    private static func socialSignIn(_ provider: AuthProvider) async throws(TitanError) -> SignInMethod {
        switch provider {
        case .apple: try await AppleSignInHelper().request()
        case .google: try await GoogleSignInHelper.request()
        default: throw .unknown("\(provider.rawValue) sign-in is not set up")
        }
    }

    nonisolated static func forcesBlockingScreen(_ arguments: [String]) -> Bool {
        arguments.contains("-maintenance") || arguments.contains("-forceUpdate")
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
            // swiftlint:disable:next force_unwrapping
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
            speech: MockSpeechRecognizer(transcripts: ["hello"]),
            chat: MockChatService(),
            roleplayAI: MockRoleplayAI()
        )
    }

    var kitVersion: String { TitanCoreModule.version }
}
