import Foundation
import TitanAuth
import TitanStorage

enum DolingoKeys {
    static let hasSeenOnboarding = PreferenceKey("dolingo.hasSeenOnboarding", default: false)
}

/// Which part of the app is showing: splash, onboarding, sign-in, or the signed-in app.
@MainActor
final class AppFlow: ObservableObject {
    enum Stage: Equatable {
        case splash, onboarding, login, home
    }

    @Published private(set) var stage: Stage = .splash
    private var stageAfterSplash: Stage = .onboarding

    private let auth: any AuthService
    private let preferences: Preferences

    init(auth: any AuthService, preferences: Preferences) {
        self.auth = auth
        self.preferences = preferences
    }

    /// Runs while the splash is up.
    func prepareLaunch() async {
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

    func signOut() async {
        try? await auth.signOut()
        stage = .login
    }
}
