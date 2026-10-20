import SwiftUI

/// Spacing steps on a 4 pt grid. Use these instead of literal paddings.
public enum Spacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

/// Corner radii. `full` makes pill-shaped buttons and round avatars.
public struct Radius: Hashable, Sendable {
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat

    public init(sm: CGFloat, md: CGFloat, lg: CGFloat) {
        self.sm = sm
        self.md = md
        self.lg = lg
    }

    public static let full: CGFloat = 1000

    public static let sharp = Radius(sm: 2, md: 4, lg: 8)
    public static let rounded = Radius(sm: 8, md: 12, lg: 16)
    public static let soft = Radius(sm: 12, md: 16, lg: 24)
}

/// Drop shadows. `radius` is SwiftUI's blur radius (half of Figma's "blur").
public struct Elevation: Hashable, Sendable {
    public var color: RGBA
    public var radius: CGFloat
    public var y: CGFloat

    public init(color: RGBA, radius: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.y = y
    }

    public static let flat = Elevation(color: RGBA(hex: 0, alpha: 0), radius: 0, y: 0)
    /// Soft shadow for cards and raised buttons.
    public static let card = Elevation(color: RGBA(hex: 0x04060F, alpha: 0.08), radius: 30, y: 4)
}

public extension View {
    func tkElevation(_ elevation: Elevation) -> some View {
        shadow(color: elevation.color.color, radius: elevation.radius, x: 0, y: elevation.y)
    }
}
