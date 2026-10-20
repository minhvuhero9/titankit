import Foundation
import SwiftUI

/// Current in-app language. Changing it redraws the UI without restarting the app.
///
///     RootView()
///         .environmentObject(container.localization)
///         .environment(\.locale, container.localization.locale)
@MainActor
public final class LocalizationService: ObservableObject {
    @Published public private(set) var currentLanguage: Language
    public let supportedLanguages: [Language]

    private let defaults: UserDefaults
    static let storageKey = "titan.language"

    /// Starts with the saved choice, else the device language if supported, else `defaultLanguage`.
    public init(
        supported: [String],
        defaultLanguage: String,
        preferredLanguages: [String] = Locale.preferredLanguages,
        defaults: UserDefaults = .standard
    ) {
        precondition(supported.contains(defaultLanguage), "defaultLanguage must be one of supported")
        self.supportedLanguages = supported.map(Language.init)
        self.defaults = defaults

        let saved = defaults.string(forKey: Self.storageKey).flatMap { supported.contains($0) ? $0 : nil }
        let device = preferredLanguages
            .compactMap { Locale(identifier: $0).language.languageCode?.identifier }
            .first(where: supported.contains)
        currentLanguage = Language(saved ?? device ?? defaultLanguage)
    }

    public var locale: Locale { currentLanguage.locale }

    public func setLanguage(_ language: Language) {
        guard supportedLanguages.contains(language), language != currentLanguage else { return }
        currentLanguage = language
        defaults.set(language.code, forKey: Self.storageKey)
    }

    /// App strings first, then the kit's, then the key itself.
    public func string(_ key: String) -> String {
        KitStrings.string(key, locale: locale)
    }

    public var formatter: TKFormatter { TKFormatter(locale: locale) }
}
