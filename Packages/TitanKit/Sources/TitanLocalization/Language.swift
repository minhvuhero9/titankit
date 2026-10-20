import Foundation

public struct Language: Hashable, Sendable, Identifiable {
    /// ISO code, e.g. "vi", "en". Must match a `.lproj` the app ships.
    public let code: String
    public var id: String { code }

    public init(_ code: String) {
        self.code = code
    }

    /// The language's own name: "Tiếng Việt", "English".
    public var displayName: String {
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forLanguageCode: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    public var locale: Locale { Locale(identifier: code) }
}
