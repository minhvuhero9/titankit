import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "upgrade plan subscription successful": a crown under falling confetti,
/// "Congratulations!", the benefits now unlocked, a note on renewal and one button.
///
///     PremiumWelcomeScreen(message: Text("premium.welcome.message"),
///                          benefits: [Text("premium.benefit.lessons")],
///                          actionTitle: Text("premium.welcome.action")) { router.dismiss() }
public struct PremiumWelcomeScreen: View {
    private let title: Text?
    private let message: Text
    private let benefitsTitle: Text?
    private let benefits: [Text]
    private let footnote: Text?
    private let actionTitle: Text
    private let action: () -> Void

    @State private var confettiFalls = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - title: "Congratulations!" when nil.
    ///   - benefitsTitle: "Benefits Unlocked:" when nil.
    public init(
        title: Text? = nil,
        message: Text,
        benefitsTitle: Text? = nil,
        benefits: [Text],
        footnote: Text? = nil,
        actionTitle: Text,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.benefitsTitle = benefitsTitle
        self.benefits = benefits
        self.footnote = footnote
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    crown
                        .padding(.top, Spacing.xl)
                    VStack(spacing: Spacing.sm) {
                        (title ?? Text.kit(KitStrings.Paywall.welcomeTitle, locale: locale))
                            .tkTextStyle(.title1)
                            .foregroundStyle(theme.colors.textPrimary.color)
                            .accessibilityAddTraits(.isHeader)
                        message
                            .tkTextStyle(.body)
                            .foregroundStyle(theme.colors.textSecondary.color)
                    }
                    .multilineTextAlignment(.center)
                    TKDivider()
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        (benefitsTitle ?? Text.kit(KitStrings.Paywall.benefitsUnlocked, locale: locale))
                            .tkTextStyle(.title3)
                            .foregroundStyle(theme.colors.textPrimary.color)
                            .frame(maxWidth: .infinity)
                        ForEach(benefits.indices, id: \.self) { index in
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(theme.colors.actionPrimary.color)
                                    .accessibilityHidden(true)
                                benefits[index]
                                    .tkTextStyle(.body)
                                    .foregroundStyle(theme.colors.textPrimary.color)
                            }
                        }
                    }
                    if let footnote {
                        TKDivider()
                        footnote
                            .tkTextStyle(.callout)
                            .foregroundStyle(theme.colors.textSecondary.color)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Spacing.lg)
            }
            VStack(spacing: Spacing.sm) {
                Divider()
                TKButton(actionTitle, shape: .pill, action: action)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .overlay(alignment: .top) { confetti }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 2.4)) { confettiFalls = true }
        }
    }

    private var crown: some View {
        Circle()
            .fill(theme.colors.feedbackWarning.color)
            .frame(width: 120, height: 120)
            .overlay {
                Image(tk: TKSymbol.crown)
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(theme.colors.actionOnPrimary.color)
            }
            .accessibilityHidden(true)
    }

    /// Paper pieces that drift down and fade once, then stay out of the way.
    private var confetti: some View {
        GeometryReader { proxy in
            ForEach(Self.pieces.indices, id: \.self) { index in
                let piece = Self.pieces[index]
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Self.colors(theme)[index % 5])
                    .frame(width: piece.width, height: piece.width * 2.4)
                    .rotationEffect(.degrees(confettiFalls ? piece.angle + 180 : piece.angle))
                    .position(x: proxy.size.width * piece.x,
                              y: confettiFalls ? piece.y + 260 : piece.y)
                    .opacity(confettiFalls ? 0 : 1)
            }
        }
        .frame(height: 200)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func colors(_ theme: Theme) -> [Color] {
        [theme.colors.actionPrimary.color, theme.colors.feedbackWarning.color, theme.colors.feedbackSuccess.color,
         theme.colors.feedbackError.color, theme.colors.feedbackInfo.color]
    }

    /// x as a share of the width, y in points, width of the piece, starting angle.
    private static let pieces: [(x: CGFloat, y: CGFloat, width: CGFloat, angle: Double)] = [
        (0.05, 30, 6, 20), (0.14, 90, 5, -35), (0.22, 18, 7, 60), (0.31, 120, 5, 10), (0.4, 55, 6, -50),
        (0.5, 12, 5, 80), (0.6, 70, 7, -20), (0.68, 140, 5, 45), (0.77, 28, 6, -70), (0.86, 100, 5, 30),
        (0.94, 50, 7, -10), (0.1, 160, 5, 55), (0.45, 165, 6, -40), (0.82, 175, 5, 15),
    ]
}
