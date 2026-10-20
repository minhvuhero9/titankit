import SwiftUI

public extension Text {
    /// A kit string for `locale`, with any override from the app's Localizable.xcstrings.
    /// Screens read the locale from the environment: `@Environment(\.locale) var locale`.
    static func kit(_ key: String, locale: Locale) -> Text {
        Text(verbatim: KitStrings.string(key, locale: locale))
    }
}
