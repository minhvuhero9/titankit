import SwiftUI
import UIKit

/// A raw colour value. Kept as numbers (not SwiftUI.Color) so themes can be compared,
/// merged and checked for contrast in tests.
public struct RGBA: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// `RGBA(hex: 0x5150FF)` for the colours designers write as #5150FF.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    public static let white = RGBA(hex: 0xFFFFFF)
    public static let black = RGBA(hex: 0x000000)

    public func opacity(_ alpha: Double) -> RGBA {
        RGBA(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Blends towards `other`: 0 keeps this colour, 1 returns `other`.
    public func mixed(with other: RGBA, by amount: Double) -> RGBA {
        let t = min(max(amount, 0), 1)
        return RGBA(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }

    public var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var color: Color { Color(uiColor) }

    // MARK: - Contrast (WCAG 2.1)

    /// Relative luminance, 0 for black and 1 for white.
    public var luminance: Double {
        func channel(_ value: Double) -> Double {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    /// Contrast ratio from 1 to 21. Body text needs at least 4.5.
    public func contrast(with other: RGBA) -> Double {
        let lighter = max(luminance, other.luminance)
        let darker = min(luminance, other.luminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Black or white, whichever reads better on this colour.
    public var readableForeground: RGBA {
        contrast(with: .white) >= contrast(with: .black) ? .white : .black
    }
}

/// A colour with a light-mode and a dark-mode value.
public struct AdaptiveColor: Hashable, Sendable {
    public var light: RGBA
    public var dark: RGBA

    public init(light: RGBA, dark: RGBA) {
        self.light = light
        self.dark = dark
    }

    /// Same value in both modes.
    public init(_ both: RGBA) {
        self.init(light: both, dark: both)
    }

    public var color: Color {
        let light = light.uiColor
        let dark = dark.uiColor
        return Color(UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }
}
