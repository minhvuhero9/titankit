/// Primitive palette: one hue in ten steps, 50 (lightest) to 900 (darkest).
/// Components never read a scale directly; ColorTokens picks steps from it.
public struct ColorScale: Hashable, Sendable {
    public static let steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]

    public let shades: [Int: RGBA]

    public init(shades: [Int: RGBA]) {
        precondition(Set(shades.keys) == Set(Self.steps), "ColorScale needs every step 50...900")
        self.shades = shades
    }

    /// Lists the ten shades from 50 to 900, e.g. straight from a Figma colour page.
    public init(_ hexes: [UInt32]) {
        precondition(hexes.count == Self.steps.count, "ColorScale needs 10 colours, 50...900")
        self.init(shades: Dictionary(uniqueKeysWithValues: zip(Self.steps, hexes.map { RGBA(hex: $0) })))
    }

    public subscript(step: Int) -> RGBA {
        guard let value = shades[step] else {
            preconditionFailure("ColorScale has no step \(step); use one of \(Self.steps)")
        }
        return value
    }
}
