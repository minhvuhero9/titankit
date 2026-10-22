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
        public static let terms = "kit.settings.terms"
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
