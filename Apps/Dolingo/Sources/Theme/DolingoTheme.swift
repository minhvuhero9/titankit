import TitanDesignSystem

/// Dolingo's look, copied from the purchased Figma template (Colors and Typography pages).
/// Only what differs from the kit's base theme is set here.
enum DolingoTheme {
    static let primary = ColorScale([
        0xEEEEFF, 0xDCDCFF, 0xCBCBFF, 0xB9B9FF, 0xA8A8FF,
        0x9796FF, 0x8585FF, 0x7473FF, 0x6262FF, 0x5150FF,
    ])
    static let secondary = ColorScale([
        0xEBEBF7, 0xD7D7F0, 0xC4C3E8, 0xB0AFE1, 0x9C9CD9,
        0x8888D1, 0x7474CA, 0x6160C2, 0x4D4CBB, 0x3938B3,
    ])
    static let greyscale = ColorScale([
        0xFAFAFA, 0xF5F5F5, 0xEEEEEE, 0xE0E0E0, 0xBDBDBD,
        0x9E9E9E, 0x757575, 0x616161, 0x424242, 0x212121,
    ])

    /// Figma "Dark" swatches, from the page background up to raised surfaces.
    enum Dark {
        static let dark1 = RGBA(hex: 0x181A20)
        static let dark2 = RGBA(hex: 0x1E2025)
        static let dark3 = RGBA(hex: 0x1F222A)
        static let dark4 = RGBA(hex: 0x262A35)
        static let dark5 = RGBA(hex: 0x35383F)
    }

    static let brand: ThemePatch = {
        var colors = ColorTokensPatch()
        colors.actionPrimary = AdaptiveColor(primary[900])
        colors.actionOnPrimary = AdaptiveColor(.white)
        colors.actionPrimaryPressed = AdaptiveColor(RGBA(hex: 0x4140CC))
        colors.actionSecondary = AdaptiveColor(light: RGBA(hex: 0xF1F1FF), dark: Dark.dark4)
        colors.actionOnSecondary = AdaptiveColor(light: primary[900], dark: .white)
        // Figma "Button Disabled": a darker brand with white text (sign-in screen, empty form).
        colors.actionDisabled = AdaptiveColor(RGBA(hex: 0x4140CC))
        colors.actionOnDisabled = AdaptiveColor(RGBA(hex: 0xFFFFFF, alpha: 0.7))
        // Figma "Disabled" swatches, used for disabled inputs.
        colors.surfaceDisabled = AdaptiveColor(light: RGBA(hex: 0xD8D8D8), dark: RGBA(hex: 0x23252B))
        colors.actionNeutral = AdaptiveColor(Dark.dark5)
        colors.actionOnNeutral = AdaptiveColor(.white)
        colors.surfaceBackground = AdaptiveColor(light: .white, dark: Dark.dark1)
        colors.surfaceCard = AdaptiveColor(light: greyscale[50], dark: Dark.dark2)
        colors.surfaceInput = AdaptiveColor(light: greyscale[50], dark: Dark.dark2)
        colors.border = AdaptiveColor(light: greyscale[200], dark: Dark.dark5)
        colors.textPrimary = AdaptiveColor(light: greyscale[900], dark: .white)
        colors.textSecondary = AdaptiveColor(light: greyscale[700], dark: greyscale[300])
        colors.textDisabled = AdaptiveColor(light: greyscale[500], dark: greyscale[600])
        colors.feedbackSuccess = AdaptiveColor(RGBA(hex: 0x12D18E))
        colors.feedbackWarning = AdaptiveColor(RGBA(hex: 0xFACC15))
        colors.feedbackError = AdaptiveColor(RGBA(hex: 0xF75555))
        colors.feedbackInfo = AdaptiveColor(RGBA(hex: 0x235DFF))

        return ThemePatch(
            colors: colors,
            // Figma's Urbanist has no đ, ơ, ư or stacked accents, so Vietnamese uses
            // Plus Jakarta Sans, the closest bundled font with full Vietnamese support.
            fontFamily: TKFonts.urbanist,
            localizedFontFamilies: ["vi": TKFonts.plusJakartaSans],
            textStyles: [
                .display: TextStyle(size: 48, weight: .bold, lineHeight: 1.4),
                .headline: TextStyle(size: 18, weight: .bold, lineHeight: 1.4),
                .body: TextStyle(size: 16, weight: .regular, lineHeight: 1.6, tracking: 0.2),
                .callout: TextStyle(size: 14, weight: .regular, lineHeight: 1.6, tracking: 0.2),
                .caption: TextStyle(size: 12, weight: .medium, lineHeight: 1.6, tracking: 0.2),
                .label: TextStyle(size: 18, weight: .semibold, lineHeight: 1.6, tracking: 0.2),
            ],
            // Figma: alert notes 6, inputs and rounded buttons 10.
            radius: Radius(sm: 6, md: 10, lg: 16),
            // Figma "Gradient Primary".
            gradientPrimary: TKGradient(from: primary[900], to: primary[700])
        )
    }()

    /// Chapter banners on Home, in turn: orange, blue, purple (Figma "Chapter" cards).
    static let chapterColors = [
        AdaptiveColor(RGBA(hex: 0xFF981F)),
        AdaptiveColor(RGBA(hex: 0x1A96F0)),
        AdaptiveColor(RGBA(hex: 0x9D28AC)),
    ]

    static let theme = Theme.base.merged(with: brand)
}
