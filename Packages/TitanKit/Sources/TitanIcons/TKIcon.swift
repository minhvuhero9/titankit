import SwiftUI

/// Line weight of an icon. `light` is the outline used across screens, `bold` is the filled one
/// for selected tabs and emphasis.
public enum TKIconStyle: String, CaseIterable, Sendable {
    case light
    case bold
}

/// Icons from the Iconly set that ships with the purchased design template.
///
/// Every icon is a template image, so it takes the current foreground colour:
///
///     TKIcon.home.image()
///         .foregroundStyle(theme.colors.actionPrimary.color)
///     Image(tk: .heart, style: .bold)
public extension TKIcon {
    /// Asset name inside the kit's catalog, for example `light.arrowLeft`.
    func assetName(_ style: TKIconStyle = .light) -> String {
        "\(style.rawValue).\(rawValue)"
    }

    func image(_ style: TKIconStyle = .light) -> Image {
        Image(assetName(style), bundle: .module)
    }
}

public extension Image {
    init(tk icon: TKIcon, style: TKIconStyle = .light) {
        self.init(icon.assetName(style), bundle: .module)
    }
}

#if canImport(UIKit)
import UIKit

public extension TKIcon {
    /// For UIKit APIs such as tab bar items.
    func uiImage(_ style: TKIconStyle = .light) -> UIImage? {
        UIImage(named: assetName(style), in: .module, with: nil)
    }
}
#endif

/// The template's second icon set ("Additional Icons"): media controls, text formatting,
/// food, gender, loading and more. One style each; filled and bold looks are separate cases
/// such as `.alarmFill` or `.checkBold`. Template images, like `TKIcon`.
public extension TKSymbol {
    var assetName: String { "symbol.\(rawValue)" }
    var image: Image { Image(assetName, bundle: .module) }
}

/// Full-colour illustrations at icon size ("Colorful Icons"): fire, coin, target, timers.
/// They keep their own colours, so `foregroundStyle` has no effect.
public extension TKColorIcon {
    var assetName: String { "color.\(rawValue)" }
    var image: Image { Image(assetName, bundle: .module) }
}

public extension Image {
    init(tk symbol: TKSymbol) {
        self.init(symbol.assetName, bundle: .module)
    }

    init(tk icon: TKColorIcon) {
        self.init(icon.assetName, bundle: .module)
    }
}

#if canImport(UIKit)
public extension TKSymbol {
    var uiImage: UIImage? { UIImage(named: assetName, in: .module, with: nil) }
}

public extension TKColorIcon {
    var uiImage: UIImage? { UIImage(named: assetName, in: .module, with: nil) }
}
#endif
