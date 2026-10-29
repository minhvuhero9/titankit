import Foundation

/// Keys of the kit's own strings (TitanKit.xcstrings). All start with "kit.".
/// An app changes one by adding the same key to its Localizable.xcstrings.
public enum KitStrings {
    public static let retry = "kit.common.retry"
    public static let ok = "kit.common.ok"
    public static let cancel = "kit.common.cancel"
    public static let showPassword = "kit.field.password.show"
    public static let hidePassword = "kit.field.password.hide"
    public static let errorTitle = "kit.error.title"
    public static let offlineTitle = "kit.error.offline.title"
    public static let back = "kit.common.back"
    public static let loading = "kit.common.loading"
    public static let search = "kit.common.search"
    public static let clear = "kit.common.clear"
    public static let previous = "kit.common.previous"
    public static let next = "kit.common.next"
    public static let currentPlan = "kit.purchase.currentPlan"

    public enum Onboarding {
        public static let getStarted = "kit.onboarding.getStarted"
        public static let haveAccount = "kit.onboarding.haveAccount"
    }

    public enum Login {
        public static let title = "kit.login.title"
        public static let subtitle = "kit.login.subtitle"
        public static let email = "kit.login.email"
        public static let password = "kit.login.password"
        public static let forgotPassword = "kit.login.forgotPassword"
        public static let orContinueWith = "kit.login.orContinueWith"
        public static let submit = "kit.login.submit"
        public static let noAccount = "kit.login.noAccount"
        public static let signUp = "kit.login.signUp"
        public static let invalidCredentials = "kit.login.error.credentials"
        public static let invalidEmail = "kit.login.error.email"
        public static let shortPassword = "kit.login.error.password"
    }

    public enum Settings {
        public static let title = "kit.settings.title"
        public static let logout = "kit.settings.logout"
        public static let logoutConfirm = "kit.settings.logout.confirm"
        public static let logoutAction = "kit.settings.logout.action"
        public static let appearance = "kit.settings.appearance"
        public static let theme = "kit.settings.theme"
        public static let chooseTheme = "kit.settings.theme.choose"
        public static let themeSystem = "kit.settings.theme.system"
        public static let themeLight = "kit.settings.theme.light"
        public static let themeDark = "kit.settings.theme.dark"
        public static let language = "kit.settings.language"
        public static let chooseLanguage = "kit.settings.language.choose"
        public static let helpSupport = "kit.settings.helpSupport"
        public static let privacy = "kit.settings.privacy"
        public static let rateApp = "kit.settings.rateApp"
        public static let terms = "kit.settings.terms"
    }

    public enum Launch {
        public static let maintenanceTitle = "kit.launch.maintenance.title"
        public static let maintenanceMessage = "kit.launch.maintenance.message"
        public static let updateTitle = "kit.launch.update.title"
        public static let updateMessage = "kit.launch.update.message"
        public static let updateAction = "kit.launch.update.action"
    }

    public enum Profile {
        public static let title = "kit.profile.title"
        public static let name = "kit.profile.name"
        public static let email = "kit.profile.email"
        public static let save = "kit.profile.save"
        public static let saved = "kit.profile.saved"
    }

    public enum DeleteAccount {
        public static let title = "kit.deleteAccount.title"
        public static let warning = "kit.deleteAccount.warning"
        public static let lossProgress = "kit.deleteAccount.loss.progress"
        public static let lossProfile = "kit.deleteAccount.loss.profile"
        public static let lossSubscription = "kit.deleteAccount.loss.subscription"
        public static let confirmCheck = "kit.deleteAccount.confirmCheck"
        public static let confirmTitle = "kit.deleteAccount.confirmTitle"
        public static let action = "kit.deleteAccount.action"
        public static let signInAgain = "kit.deleteAccount.signInAgain"
    }

    public enum Paywall {
        public static let title = "kit.paywall.title"
        public static let message = "kit.paywall.message"
        public static let close = "kit.paywall.close"
        public static let popular = "kit.paywall.popular"
        public static let choose = "kit.paywall.choose"
        public static let startTrial = "kit.paywall.startTrial"
        public static let perDay = "kit.paywall.period.day"
        public static let perWeek = "kit.paywall.period.week"
        public static let perMonth = "kit.paywall.period.month"
        public static let perYear = "kit.paywall.period.year"
        /// Days of the free trial, then the price and period after it.
        public static let trial = "kit.paywall.trial %lld %@"
        public static let autoRenew = "kit.paywall.autoRenew"
        public static let restore = "kit.paywall.restore"
        public static let nothingToRestore = "kit.paywall.restore.nothing"
        public static let pending = "kit.paywall.pending"
    }

    /// Looks the key up for `locale`: app bundle (Localizable) first, then the kit (TitanKit),
    /// then returns the key so a missing string is easy to spot.
    public static func string(_ key: String, locale: Locale, appBundle: Bundle = .main) -> String {
        let code = locale.language.languageCode?.identifier ?? "vi"
        if let value = lookup(key, table: "Localizable", in: appBundle, language: code) { return value }
        if let value = lookup(key, table: "TitanKit", in: .module, language: code) { return value }
        return key
    }

    static func lookup(_ key: String, table: String, in bundle: Bundle, language: String) -> String? {
        let localized = bundle.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle
        let value = localized.localizedString(forKey: key, value: missing, table: table)
        return value == missing ? nil : value
    }

    private static let missing = "\u{0}titan.missing"
}
