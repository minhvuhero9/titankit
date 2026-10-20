import Foundation

/// Builds a full palette from one brand colour, so an app without a designer still gets
/// consistent light and dark colours.
public enum PaletteGenerator {
    /// Lightness for each step, from 50 (almost white) to 900 (deep).
    static let lightness: [Int: Double] = [
        50: 0.96, 100: 0.92, 200: 0.84, 300: 0.75, 400: 0.66,
        500: 0.56, 600: 0.47, 700: 0.39, 800: 0.31, 900: 0.23,
    ]

    /// Same hue and saturation as the brand, ten lightness steps.
    public static func scale(from brand: RGBA) -> ColorScale {
        let (hue, saturation, _) = hsl(brand)
        var shades: [Int: RGBA] = [:]
        for step in ColorScale.steps {
            shades[step] = rgb(hue: hue, saturation: saturation, lightness: lightness[step] ?? 0.5)
        }
        return ColorScale(shades: shades)
    }

    /// Semantic colours for light and dark mode. The brand is kept as is for the primary action.
    public static func tokens(from brand: RGBA) -> ColorTokens {
        let primary = scale(from: brand)
        let neutral = Neutral.self
        let darkPrimary = primary[400]

        return ColorTokens(
            actionPrimary: AdaptiveColor(light: brand, dark: darkPrimary),
            actionOnPrimary: AdaptiveColor(light: brand.readableForeground, dark: darkPrimary.readableForeground),
            actionSecondary: AdaptiveColor(light: primary[50], dark: neutral.dark3),
            actionOnSecondary: AdaptiveColor(light: primary[700], dark: primary[200]),
            actionDisabled: AdaptiveColor(light: neutral.grey200, dark: neutral.dark3),
            actionOnDisabled: AdaptiveColor(light: neutral.grey500, dark: neutral.grey600),
            surfaceBackground: AdaptiveColor(light: .white, dark: neutral.dark1),
            surfaceCard: AdaptiveColor(light: .white, dark: neutral.dark2),
            surfaceInput: AdaptiveColor(light: neutral.grey50, dark: neutral.dark2),
            border: AdaptiveColor(light: neutral.grey200, dark: neutral.dark3),
            textPrimary: AdaptiveColor(light: neutral.grey900, dark: .white),
            textSecondary: AdaptiveColor(light: neutral.grey700, dark: neutral.grey300),
            textDisabled: AdaptiveColor(light: neutral.grey500, dark: neutral.grey600),
            feedbackSuccess: AdaptiveColor(RGBA(hex: 0x16A34A)),
            feedbackWarning: AdaptiveColor(RGBA(hex: 0xEAB308)),
            feedbackError: AdaptiveColor(light: RGBA(hex: 0xDC2626), dark: RGBA(hex: 0xF87171)),
            feedbackInfo: AdaptiveColor(light: RGBA(hex: 0x2563EB), dark: RGBA(hex: 0x60A5FA))
        )
    }

    private enum Neutral {
        static let grey50 = RGBA(hex: 0xF8F9FB)
        static let grey200 = RGBA(hex: 0xE4E7EC)
        static let grey300 = RGBA(hex: 0xD0D5DD)
        static let grey500 = RGBA(hex: 0x98A2B3)
        static let grey600 = RGBA(hex: 0x667085)
        static let grey700 = RGBA(hex: 0x475467)
        static let grey900 = RGBA(hex: 0x101828)
        static let dark1 = RGBA(hex: 0x0F1115)
        static let dark2 = RGBA(hex: 0x1A1D23)
        static let dark3 = RGBA(hex: 0x272B33)
    }

    // MARK: - HSL

    static func hsl(_ color: RGBA) -> (hue: Double, saturation: Double, lightness: Double) {
        let maxValue = max(color.red, color.green, color.blue)
        let minValue = min(color.red, color.green, color.blue)
        let lightness = (maxValue + minValue) / 2
        let delta = maxValue - minValue
        guard delta > 0 else { return (0, 0, lightness) }

        let saturation = delta / (1 - abs(2 * lightness - 1))
        var hue: Double
        switch maxValue {
        case color.red: hue = ((color.green - color.blue) / delta).truncatingRemainder(dividingBy: 6)
        case color.green: hue = (color.blue - color.red) / delta + 2
        default: hue = (color.red - color.green) / delta + 4
        }
        hue *= 60
        if hue < 0 { hue += 360 }
        return (hue, saturation, lightness)
    }

    static func rgb(hue: Double, saturation: Double, lightness: Double) -> RGBA {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let x = chroma * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - chroma / 2
        let (r, g, b): (Double, Double, Double) = switch hue {
        case ..<60: (chroma, x, 0)
        case ..<120: (x, chroma, 0)
        case ..<180: (0, chroma, x)
        case ..<240: (0, x, chroma)
        case ..<300: (x, 0, chroma)
        default: (chroma, 0, x)
        }
        return RGBA(red: r + m, green: g + m, blue: b + m)
    }
}
