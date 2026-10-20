import SwiftUI
import UIKit

/// Text roles used by components and screens. Each maps to a size, weight and line height.
public enum TextRole: String, CaseIterable, Sendable {
    case display, title1, title2, title3, headline, body, callout, caption
    /// Field labels and other small headings that sit above a control.
    case label

    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title1: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .caption: .caption1
        case .label: .subheadline
        }
    }

    /// The Dynamic Type style this role scales with.
    var dynamicTypeStyle: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title1: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .caption: .caption
        case .label: .subheadline
        }
    }
}

public struct TextStyle: Hashable, Sendable {
    public enum Weight: String, Hashable, Sendable {
        case regular, medium, semibold, bold

        var font: Font.Weight {
            switch self {
            case .regular: .regular
            case .medium: .medium
            case .semibold: .semibold
            case .bold: .bold
            }
        }
    }

    public var size: CGFloat
    public var weight: Weight
    /// Line height as a multiple of the size (Figma's "140%" is 1.4).
    public var lineHeight: CGFloat
    /// Extra space between letters in points.
    public var tracking: CGFloat

    public init(size: CGFloat, weight: Weight, lineHeight: CGFloat = 1.4, tracking: CGFloat = 0) {
        self.size = size
        self.weight = weight
        self.lineHeight = lineHeight
        self.tracking = tracking
    }
}

public struct Typography: Hashable, Sendable {
    /// Custom font family name, as registered in the app. nil uses the system font.
    public var fontFamily: String?
    public var styles: [TextRole: TextStyle]

    public init(fontFamily: String? = nil, styles: [TextRole: TextStyle]) {
        precondition(Set(styles.keys) == Set(TextRole.allCases), "Typography needs a style for every TextRole")
        self.fontFamily = fontFamily
        self.styles = styles
    }

    public func style(_ role: TextRole) -> TextStyle {
        styles[role] ?? TextStyle(size: 16, weight: .regular)
    }

    /// Scales with Dynamic Type. Falls back to the system font if the family is not installed.
    public func font(_ role: TextRole) -> Font {
        let style = style(role)
        return font(size: style.size, weight: style.weight, relativeTo: role)
    }

    /// A one-off size in the theme's font family, for components whose text size depends on
    /// their own size (button heights). Still scales with Dynamic Type.
    public func font(size: CGFloat, weight: TextStyle.Weight, relativeTo role: TextRole = .body) -> Font {
        let base: Font = if let fontFamily {
            .custom(fontFamily, size: size, relativeTo: role.dynamicTypeStyle)
        } else {
            .system(size: UIFontMetrics(forTextStyle: role.uiTextStyle).scaledValue(for: size))
        }
        return base.weight(weight.font)
    }

    /// Extra spacing between lines so the text matches the design's line height.
    public func lineSpacing(_ role: TextRole) -> CGFloat {
        let style = style(role)
        return max(0, style.size * (style.lineHeight - 1))
    }
}
