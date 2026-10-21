import SwiftUI

/// Everything that makes an app look like itself. Components read it from the environment.
public struct Theme: Hashable, Sendable {
    public var colors: ColorTokens
    public var typography: Typography
    public var radius: Radius
    /// The brand gradient (Figma "Gradient Primary"), for banners and highlighted cards.
    public var gradientPrimary: TKGradient
    /// Name of the logo image in the app's asset catalog.
    public var logoName: String?

    public init(
        colors: ColorTokens,
        typography: Typography,
        radius: Radius,
        gradientPrimary: TKGradient? = nil,
        logoName: String? = nil
    ) {
        self.colors = colors
        self.typography = typography
        self.radius = radius
        // Without a design, fade from the brand colour to a lighter step of it.
        let brand = colors.actionPrimary.light
        self.gradientPrimary = gradientPrimary ?? TKGradient(from: brand, to: brand.mixed(with: .white, by: 0.2))
        self.logoName = logoName
    }

    /// Layer 1: the kit's default look. Any app runs with it, no design needed.
    public static let base = Theme(
        colors: PaletteGenerator.tokens(from: RGBA(hex: 0x2F5BEA)),
        typography: .base,
        radius: .rounded
    )

    /// Layers 2 and 3: apply the app's brand, then any Figma override. Later layers win.
    public func merged(with patch: ThemePatch) -> Theme {
        var result = self
        if let colors = patch.colors { result.colors = result.colors.merged(with: colors) }
        if let fontFamily = patch.fontFamily { result.typography.fontFamily = fontFamily }
        if let families = patch.localizedFontFamilies { result.typography.localizedFontFamilies = families }
        if let styles = patch.textStyles { result.typography.styles.merge(styles) { _, new in new } }
        if let radius = patch.radius { result.radius = radius }
        if let gradient = patch.gradientPrimary { result.gradientPrimary = gradient }
        if let logoName = patch.logoName { result.logoName = logoName }
        return result
    }
}

/// One theme layer. Every field is optional; nil keeps the value from the layer below.
public struct ThemePatch: Hashable, Sendable {
    public var colors: ColorTokensPatch?
    public var fontFamily: String?
    public var localizedFontFamilies: [String: String]?
    public var textStyles: [TextRole: TextStyle]?
    public var radius: Radius?
    public var gradientPrimary: TKGradient?
    public var logoName: String?

    public init(
        colors: ColorTokensPatch? = nil,
        fontFamily: String? = nil,
        localizedFontFamilies: [String: String]? = nil,
        textStyles: [TextRole: TextStyle]? = nil,
        radius: Radius? = nil,
        gradientPrimary: TKGradient? = nil,
        logoName: String? = nil
    ) {
        self.colors = colors
        self.fontFamily = fontFamily
        self.localizedFontFamilies = localizedFontFamilies
        self.textStyles = textStyles
        self.radius = radius
        self.gradientPrimary = gradientPrimary
        self.logoName = logoName
    }
}

public extension Typography {
    /// The kit's default type scale, on the system font.
    static let base = Typography(styles: [
        .display: TextStyle(size: 40, weight: .bold, lineHeight: 1.2),
        .title1: TextStyle(size: 32, weight: .bold, lineHeight: 1.2),
        .title2: TextStyle(size: 24, weight: .bold, lineHeight: 1.3),
        .title3: TextStyle(size: 20, weight: .semibold, lineHeight: 1.3),
        .headline: TextStyle(size: 17, weight: .semibold, lineHeight: 1.4),
        .body: TextStyle(size: 16, weight: .regular, lineHeight: 1.5),
        .callout: TextStyle(size: 14, weight: .regular, lineHeight: 1.4),
        .caption: TextStyle(size: 12, weight: .regular, lineHeight: 1.4),
        .label: TextStyle(size: 15, weight: .semibold, lineHeight: 1.4),
    ])
}
