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
