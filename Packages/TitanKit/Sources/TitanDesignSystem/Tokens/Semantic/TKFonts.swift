import CoreText
import Foundation

/// Fonts that ship with the kit (SIL Open Font License, see Resources/Fonts).
/// They are registered the first time `titanTheme(_:)` runs, so apps need no Info.plist entry.
public enum TKFonts {
    /// The template's font (Figma "Typography 1"). It has no glyphs for đ, ơ, ư and most
    /// stacked Vietnamese accents, so pair it with `plusJakartaSans` for Vietnamese.
    public static let urbanist = "Urbanist"
    /// Close to Urbanist in shape, with full Vietnamese support.
    public static let plusJakartaSans = "Plus Jakarta Sans"

    /// Registers the bundled fonts once per process. Safe to call repeatedly.
    public static func registerBundledFonts() {
        _ = registration
    }

    /// The PostScript name of one weight, e.g. "Urbanist-SemiBold".
    static func postScriptName(family: String, weight: TextStyle.Weight) -> String {
        let suffix = switch weight {
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        }
        return family.replacingOccurrences(of: " ", with: "") + "-" + suffix
    }

    private static let registration: Void = {
        let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            // Already-registered fonts return an error we can ignore.
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
