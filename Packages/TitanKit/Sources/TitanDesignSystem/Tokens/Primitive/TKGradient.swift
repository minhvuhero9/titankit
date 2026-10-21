import SwiftUI

/// A linear gradient as plain values, so themes can store and compare it.
public struct TKGradient: Hashable, Sendable {
    public struct Stop: Hashable, Sendable {
        public var color: RGBA
        public var location: Double

        public init(_ color: RGBA, at location: Double) {
            self.color = color
            self.location = location
        }
    }

    public var stops: [Stop]
    public var start: UnitPoint
    public var end: UnitPoint

    public init(stops: [Stop], start: UnitPoint, end: UnitPoint) {
        self.stops = stops
        self.start = start
        self.end = end
    }

    /// The template's direction: darker colour bottom-right, lighter top-left.
    public init(from dark: RGBA, to light: RGBA) {
        self.init(stops: [Stop(dark, at: 0), Stop(light, at: 1)], start: .bottomTrailing, end: .topLeading)
    }

    public var linearGradient: LinearGradient {
        LinearGradient(
            stops: stops.map { Gradient.Stop(color: $0.color.color, location: $0.location) },
            startPoint: start,
            endPoint: end
        )
    }
}

/// Colours from the template's Colors page that any app can use, whatever its brand.
public enum TKPalette {
    /// Figma "Gradients". Teal is a flat colour in the template, so both ends match.
    public enum Gradients {
        public static let blue = TKGradient(from: RGBA(hex: 0x235DFF), to: RGBA(hex: 0x4F7DFF))
        public static let purple = TKGradient(from: RGBA(hex: 0x7E6DFC), to: RGBA(hex: 0x8B7CFC))
        public static let green = TKGradient(from: RGBA(hex: 0x00A86B), to: RGBA(hex: 0x33B989))
        public static let orange = TKGradient(from: RGBA(hex: 0xFF6347), to: RGBA(hex: 0xFF826C))
        public static let red = TKGradient(from: RGBA(hex: 0xFE3323), to: RGBA(hex: 0xFE5C4F))
        public static let teal = TKGradient(from: RGBA(hex: 0x1A998E), to: RGBA(hex: 0x1A998E))
        public static let brown = TKGradient(from: RGBA(hex: 0xA4634D), to: RGBA(hex: 0xAC7E6E))
        public static let yellow = TKGradient(from: RGBA(hex: 0xFACC15), to: RGBA(hex: 0xFFE580))
    }

    /// Figma "Background": light tints behind cards and icons of the matching colour.
    public enum Tints {
        public static let blue = RGBA(hex: 0xEDF2FF)
        public static let purple = RGBA(hex: 0xF5F3FF)
        public static let green = RGBA(hex: 0xEBF8F3)
        public static let orange = RGBA(hex: 0xFFF3F0)
        public static let red = RGBA(hex: 0xFFEFED)
        public static let teal = RGBA(hex: 0xEDF7F6)
        public static let brown = RGBA(hex: 0xF8F3F1)
        public static let yellow = RGBA(hex: 0xFFFCEB)
        public static let grey = RGBA(hex: 0xF6F6F6)
    }
}
