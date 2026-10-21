import SwiftUI
import TitanIcons

/// Figma "Modal": a centred card with an illustration, a title, a message and up to two buttons.
/// Show it over a screen with `.tkModal(isPresented:)`.
///
///     .tkModal(isPresented: $showDone) {
///         TKModal("Chúc mừng!", message: "Bạn đã hoàn thành bài học.",
///                 primary: .init("Tiếp tục") { showDone = false }) {
///             TKSuccessIllustration(.confetti)
///         }
///     }
public struct TKModal<Illustration: View>: View {
    private let title: Text
    private let message: Text?
    private let primary: TKModalAction?
    private let secondary: TKModalAction?
    private let isLoading: Bool
    private let illustration: Illustration

    @Environment(\.theme) private var theme

    /// - Parameters:
    ///   - primary: filled brand button.
    ///   - secondary: soft button under the primary one.
    ///   - isLoading: shows a spinner under the text instead of the buttons.
    public init(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        primary: TKModalAction? = nil,
        secondary: TKModalAction? = nil,
        isLoading: Bool = false,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.init(title: Text(title), message: message.map { Text($0) }, primary: primary,
                  secondary: secondary, isLoading: isLoading, illustration: illustration)
    }

    public init(
        title: Text,
        message: Text? = nil,
        primary: TKModalAction? = nil,
        secondary: TKModalAction? = nil,
        isLoading: Bool = false,
        @ViewBuilder illustration: () -> Illustration
    ) {
        self.title = title
        self.message = message
        self.primary = primary
        self.secondary = secondary
        self.isLoading = isLoading
        self.illustration = illustration()
    }

    public var body: some View {
        VStack(spacing: Spacing.xl) {
            illustration
            VStack(spacing: Spacing.sm) {
                title
                    .font(theme.typography.font(size: 24, weight: .bold, relativeTo: .title2))
                message?
                    .font(theme.typography.font(size: 16, weight: .regular, relativeTo: .body))
            }
            .foregroundStyle(theme.colors.textPrimary.color)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(theme.colors.actionPrimary.color)
            } else if primary != nil || secondary != nil {
                VStack(spacing: Spacing.sm) {
                    if let primary {
                        TKButton(primary.title, size: .medium, shape: .pill, action: primary.action)
                    }
                    if let secondary {
                        TKButton(secondary.title, style: .light, size: .medium, shape: .pill, action: secondary.action)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 40, leading: Spacing.xl, bottom: Spacing.xl, trailing: Spacing.xl))
        .frame(maxWidth: 340)
        .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

/// One button of a `TKModal`.
public struct TKModalAction {
    let title: Text
    let action: () -> Void

    public init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.init(title: Text(title), action: action)
    }

    public init(title: Text, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

public extension TKModal where Illustration == EmptyView {
    init(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        primary: TKModalAction? = nil,
        secondary: TKModalAction? = nil,
        isLoading: Bool = false
    ) {
        self.init(title, message: message, primary: primary, secondary: secondary, isLoading: isLoading) { EmptyView() }
    }

    init(title: Text, message: Text? = nil, primary: TKModalAction? = nil, secondary: TKModalAction? = nil, isLoading: Bool = false) {
        self.init(title: title, message: message, primary: primary, secondary: secondary, isLoading: isLoading) { EmptyView() }
    }
}

public extension View {
    /// Dims the screen and shows `content` in the middle while `isPresented` is true.
    ///
    /// The modal covers the view it is attached to, so attach it to the screen's root
    /// (for example the NavigationStack) to cover the navigation bar too.
    /// - Parameter dismissOnBackgroundTap: lets a tap outside the card close it.
    func tkModal<Content: View>(
        isPresented: Binding<Bool>,
        dismissOnBackgroundTap: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ModalModifier(isPresented: isPresented, dismissOnBackgroundTap: dismissOnBackgroundTap, card: content))
    }
}

private struct ModalModifier<Card: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dismissOnBackgroundTap: Bool
    let card: () -> Card

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture { if dismissOnBackgroundTap { isPresented = false } }
                            .accessibilityHidden(true)
                            .transition(.opacity)
                        card()
                            .padding(Spacing.lg)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented)
    }
}

/// Figma "Successful Illustrations": the brand circle with a tick, with or without confetti dots.
public struct TKSuccessIllustration: View {
    public enum Style: String, CaseIterable, Sendable {
        /// An 80 pt circle with a tick.
        case checkmark
        /// A larger circle with a tick square and scattered dots, for big wins.
        case confetti
    }

    private let style: Style
    @Environment(\.theme) private var theme

    public init(_ style: Style = .checkmark) {
        self.style = style
    }

    public var body: some View {
        let brand = theme.colors.actionPrimary.color
        Group {
            switch style {
            case .checkmark:
                Circle()
                    .fill(brand)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(tk: TKSymbol.check)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundStyle(theme.colors.actionOnPrimary.color)
                    }
            case .confetti:
                // Positions from the Figma frame (186 × 180), drawn at 150 pt wide.
                let scale: CGFloat = 150 / 186
                ZStack(alignment: .topLeading) {
                    ForEach(Self.confettiDots.indices, id: \.self) { index in
                        let dot = Self.confettiDots[index]
                        Circle()
                            .fill(brand)
                            .frame(width: dot.size * scale, height: dot.size * scale)
                            .offset(x: dot.x * scale, y: dot.y * scale)
                    }
                    Image(tk: TKIcon.tickSquare, style: .bold)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60 * scale, height: 60 * scale)
                        .foregroundStyle(theme.colors.actionOnPrimary.color)
                        .offset(x: 66 * scale, y: 62 * scale)
                }
                .frame(width: 186 * scale, height: 180 * scale, alignment: .topLeading)
            }
        }
        .accessibilityHidden(true)
    }

    /// The big circle comes first so the small dots and the tick sit on top.
    private static let confettiDots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (25, 21, 141), (59, 173, 7), (121, 170, 2), (5, 128, 10), (163, 158, 5),
        (168, 108, 5), (0, 74, 2), (171, 20, 15), (104, 2, 5), (10, 0, 20),
    ]
}
