/// Semantic colours: named by what they are for, not by how they look.
/// Components only use these, so a new brand never touches component code.
public struct ColorTokens: Hashable, Sendable {
    public var actionPrimary: AdaptiveColor
    public var actionOnPrimary: AdaptiveColor
    /// Soft background for secondary buttons and chips.
    public var actionSecondary: AdaptiveColor
    public var actionOnSecondary: AdaptiveColor
    public var actionDisabled: AdaptiveColor
    public var actionOnDisabled: AdaptiveColor

    public var surfaceBackground: AdaptiveColor
    public var surfaceCard: AdaptiveColor
    /// Text fields, segmented controls and other filled inputs.
    public var surfaceInput: AdaptiveColor
    public var border: AdaptiveColor

    public var textPrimary: AdaptiveColor
    public var textSecondary: AdaptiveColor
    public var textDisabled: AdaptiveColor

    public var feedbackSuccess: AdaptiveColor
    public var feedbackWarning: AdaptiveColor
    public var feedbackError: AdaptiveColor
    public var feedbackInfo: AdaptiveColor

    public init(
        actionPrimary: AdaptiveColor,
        actionOnPrimary: AdaptiveColor,
        actionSecondary: AdaptiveColor,
        actionOnSecondary: AdaptiveColor,
        actionDisabled: AdaptiveColor,
        actionOnDisabled: AdaptiveColor,
        surfaceBackground: AdaptiveColor,
        surfaceCard: AdaptiveColor,
        surfaceInput: AdaptiveColor,
        border: AdaptiveColor,
        textPrimary: AdaptiveColor,
        textSecondary: AdaptiveColor,
        textDisabled: AdaptiveColor,
        feedbackSuccess: AdaptiveColor,
        feedbackWarning: AdaptiveColor,
        feedbackError: AdaptiveColor,
        feedbackInfo: AdaptiveColor
    ) {
        self.actionPrimary = actionPrimary
        self.actionOnPrimary = actionOnPrimary
        self.actionSecondary = actionSecondary
        self.actionOnSecondary = actionOnSecondary
        self.actionDisabled = actionDisabled
        self.actionOnDisabled = actionOnDisabled
        self.surfaceBackground = surfaceBackground
        self.surfaceCard = surfaceCard
        self.surfaceInput = surfaceInput
        self.border = border
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textDisabled = textDisabled
        self.feedbackSuccess = feedbackSuccess
        self.feedbackWarning = feedbackWarning
        self.feedbackError = feedbackError
        self.feedbackInfo = feedbackInfo
    }
}

/// Partial ColorTokens: only the fields that are set replace the lower layer.
public struct ColorTokensPatch: Hashable, Sendable {
    public var actionPrimary: AdaptiveColor?
    public var actionOnPrimary: AdaptiveColor?
    public var actionSecondary: AdaptiveColor?
    public var actionOnSecondary: AdaptiveColor?
    public var actionDisabled: AdaptiveColor?
    public var actionOnDisabled: AdaptiveColor?
    public var surfaceBackground: AdaptiveColor?
    public var surfaceCard: AdaptiveColor?
    public var surfaceInput: AdaptiveColor?
    public var border: AdaptiveColor?
    public var textPrimary: AdaptiveColor?
    public var textSecondary: AdaptiveColor?
    public var textDisabled: AdaptiveColor?
    public var feedbackSuccess: AdaptiveColor?
    public var feedbackWarning: AdaptiveColor?
    public var feedbackError: AdaptiveColor?
    public var feedbackInfo: AdaptiveColor?

    public init() {}

    /// A patch that replaces every colour.
    public init(_ tokens: ColorTokens) {
        actionPrimary = tokens.actionPrimary
        actionOnPrimary = tokens.actionOnPrimary
        actionSecondary = tokens.actionSecondary
        actionOnSecondary = tokens.actionOnSecondary
        actionDisabled = tokens.actionDisabled
        actionOnDisabled = tokens.actionOnDisabled
        surfaceBackground = tokens.surfaceBackground
        surfaceCard = tokens.surfaceCard
        surfaceInput = tokens.surfaceInput
        border = tokens.border
        textPrimary = tokens.textPrimary
        textSecondary = tokens.textSecondary
        textDisabled = tokens.textDisabled
        feedbackSuccess = tokens.feedbackSuccess
        feedbackWarning = tokens.feedbackWarning
        feedbackError = tokens.feedbackError
        feedbackInfo = tokens.feedbackInfo
    }
}

public extension ColorTokens {
    func merged(with patch: ColorTokensPatch) -> ColorTokens {
        var result = self
        result.actionPrimary = patch.actionPrimary ?? actionPrimary
        result.actionOnPrimary = patch.actionOnPrimary ?? actionOnPrimary
        result.actionSecondary = patch.actionSecondary ?? actionSecondary
        result.actionOnSecondary = patch.actionOnSecondary ?? actionOnSecondary
        result.actionDisabled = patch.actionDisabled ?? actionDisabled
        result.actionOnDisabled = patch.actionOnDisabled ?? actionOnDisabled
        result.surfaceBackground = patch.surfaceBackground ?? surfaceBackground
        result.surfaceCard = patch.surfaceCard ?? surfaceCard
        result.surfaceInput = patch.surfaceInput ?? surfaceInput
        result.border = patch.border ?? border
        result.textPrimary = patch.textPrimary ?? textPrimary
        result.textSecondary = patch.textSecondary ?? textSecondary
        result.textDisabled = patch.textDisabled ?? textDisabled
        result.feedbackSuccess = patch.feedbackSuccess ?? feedbackSuccess
        result.feedbackWarning = patch.feedbackWarning ?? feedbackWarning
        result.feedbackError = patch.feedbackError ?? feedbackError
        result.feedbackInfo = patch.feedbackInfo ?? feedbackInfo
        return result
    }
}
