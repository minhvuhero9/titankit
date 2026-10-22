import Foundation
import TitanAuth
import TitanDesignSystem
import TitanRemoteConfig
import TitanStorage

enum DolingoKeys {
    static let hasSeenOnboarding = PreferenceKey("dolingo.hasSeenOnboarding", default: false)
    /// Light, dark or follow the device, picked on the App Appearance screen.
    static let appearance = PreferenceKey<TKAppearance>("dolingo.appearance", default: .system)
}

/// Which part of the app is showing: splash, onboarding, sign-in, the signed-in app,
/// or a screen that blocks the app (maintenance, forced update).
@MainActor
final class AppFlow: ObservableObject {
    enum Stage: Equatable {
        case splash, onboarding, login, home
        case maintenance(message: String)
        case forceUpdate(storeURL: URL)
    }

    @Published private(set) var stage: Stage = .splash
    private var stageAfterSplash: Stage = .onboarding

    private let auth: any AuthService
    private let preferences: Preferences
    private let launchChecker: LaunchChecker?

    /// - Parameter launchChecker: nil skips the maintenance and update check.
    init(auth: any AuthService, preferences: Preferences, launchChecker: LaunchChecker? = nil) {
        self.auth = auth
        self.preferences = preferences
        self.launchChecker = launchChecker
    }

    /// Runs while the splash is up.
    func prepareLaunch() async {
        if let blocked = await blockingStage() {
            stageAfterSplash = blocked
            return
        }
        await chooseFirstScreen()
    }

    /// "Thử lại" on the maintenance screen: checks again and lets the user in once it's over.
    func retryLaunch() async {
        if let blocked = await blockingStage() {
            stage = blocked
            return
        }
        await chooseFirstScreen()
        stage = stageAfterSplash
    }

    private func blockingStage() async -> Stage? {
        let status = await launchChecker?.check() ?? .ok
        switch status {
        case .ok: return nil
        case let .maintenance(message): return .maintenance(message: message)
        case let .forceUpdate(storeURL): return .forceUpdate(storeURL: storeURL)
        }
    }

    private func chooseFirstScreen() async {
        if await auth.currentUser() != nil {
            stageAfterSplash = .home
        } else if preferences.value(DolingoKeys.hasSeenOnboarding) {
            stageAfterSplash = .login
        } else {
            stageAfterSplash = .onboarding
        }
    }

    func finishSplash() {
        stage = stageAfterSplash
    }

    /// Both welcome buttons lead to sign-in until the sign-up questionnaire exists.
    func finishOnboarding() {
        preferences.set(true, for: DolingoKeys.hasSeenOnboarding)
        stage = .login
    }

    func didSignIn() {
        stage = .home
    }

    /// Apple, Google and Facebook sign-in arrive with the Firebase adapter (phase 4).
    /// Until then their buttons sign in as a guest so the flow can be tried end to end.
    func signInWithSocial(_ provider: AuthProvider) async {
        guard (try? await auth.signIn(.anonymous)) != nil else { return }
        didSignIn()
    }

    /// The account is already gone on the backend; back to sign-in.
    func didDeleteAccount() {
        stage = .login
    }

    func signOut() async {
        try? await auth.signOut()
        stage = .login
    }
}
