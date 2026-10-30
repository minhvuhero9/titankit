import SwiftUI
import TitanDesignSystem
import TitanLocalization

public struct OnboardingPage: Identifiable {
    public let id = UUID()
    public var image: Image
    public var title: Text
    public var message: Text

    public init(image: Image, title: LocalizedStringKey, message: LocalizedStringKey) {
        self.image = image
        self.title = Text(title)
        self.message = Text(message)
    }
}

public struct OnboardingConfig {
    public var pages: [OnboardingPage]
    /// Shows "I already have an account" under the main button.
    public var showsSignIn: Bool

    public init(pages: [OnboardingPage], showsSignIn: Bool = true) {
        precondition(!pages.isEmpty, "Onboarding needs at least one page")
        self.pages = pages
        self.showsSignIn = showsSignIn
    }
}

/// Welcome pages: picture on a brand background, title and message, page dots, then
/// "Get Started" and "I Already Have an Account". Layout follows the Dolingo welcome screen.
public struct OnboardingScreen: View {
    private let config: OnboardingConfig
    private let onGetStarted: () -> Void
    private let onSignIn: () -> Void

    @State private var index = 0
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    public init(config: OnboardingConfig, onGetStarted: @escaping () -> Void, onSignIn: @escaping () -> Void = {}) {
        self.config = config
        self.onGetStarted = onGetStarted
        self.onSignIn = onSignIn
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(config.pages.enumerated()), id: \.element.id) { item in
                    PageView(page: item.element).tag(item.offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: Spacing.md) {
                if config.pages.count > 1 {
                    PageDots(count: config.pages.count, index: index)
                        .padding(.vertical, Spacing.sm)
                }
                TKButton(Text.kit(KitStrings.Onboarding.getStarted, locale: locale), style: .threeD) {
                    onGetStarted()
                }
                if config.showsSignIn {
                    TKButton(Text.kit(KitStrings.Onboarding.haveAccount, locale: locale), style: .light) {
                        onSignIn()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkButtonShape(.pill)
    }
}

private struct PageView: View {
    let page: OnboardingPage
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.lg) {
            page.image
                .resizable().scaledToFit()
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .background(theme.colors.actionPrimary.color.ignoresSafeArea(edges: .top))
                .accessibilityHidden(true)
            VStack(spacing: Spacing.sm) {
                page.title
                    .tkTextStyle(.title1)
                    .foregroundStyle(theme.colors.textPrimary.color)
                page.message
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
            // Room above the buttons, which sit right under the page.
            .padding(.bottom, Spacing.xl)
        }
    }
}

/// Current page is a wide pill, the rest small dots, as in the Figma welcome screen.
private struct PageDots: View {
    let count: Int
    let index: Int
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill((dot == index ? theme.colors.actionPrimary : theme.colors.actionDisabled).color)
                    .frame(width: dot == index ? 32 : 8, height: 8)
            }
        }
        .animation(.easeOut(duration: 0.2), value: index)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: String(
            format: KitStrings.string("kit.onboarding.page %lld of %lld", locale: locale), index + 1, count
        )))
    }
}
