import SwiftUI
import TitanIcons
import TitanLocalization

/// Figma "Navbar": back arrow, a large title (or a progress bar) and up to three icon buttons.
///
///     LessonList()
///         .tkNavigationBar("Bài học", onBack: { router.pop() }) {
///             TKNavBarButton(Image(tk: .search), accessibilityLabel: "Tìm") { ... }
///         }
///
///     QuizScreen()
///         .tkNavigationBar(progress: vm.progress, onBack: { router.pop() })
public struct TKNavBar<Trailing: View>: View {
    private enum Center {
        case title(Text)
        case progress(Double)
    }

    private let center: Center?
    private let onBack: (() -> Void)?
    private let trailing: Trailing

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    public init(
        _ title: LocalizedStringKey? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(title: title.map { Text($0) }, onBack: onBack, trailing: trailing)
    }

    public init(title: Text?, onBack: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
        center = title.map { .title($0) }
        self.onBack = onBack
        self.trailing = trailing()
    }

    /// Progress from 0 to 1 in place of the title, e.g. the steps of a quiz.
    public init(progress: Double, onBack: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
        center = .progress(progress)
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            if let onBack {
                TKNavBarButton(Image(tk: .arrowLeft), accessibilityLabel: KitStrings.string(KitStrings.back, locale: locale), action: onBack)
            }
            switch center {
            case let .title(title)?:
                title
                    .tkTextStyle(.title2)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
            case let .progress(value)?:
                TKProgressBar(value: value)
                    .padding(.horizontal, Spacing.lg)
            case nil:
                Spacer(minLength: 0)
            }
            HStack(spacing: 20) { trailing }
        }
        .frame(height: 48)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

public extension TKNavBar where Trailing == EmptyView {
    init(_ title: LocalizedStringKey? = nil, onBack: (() -> Void)? = nil) {
        self.init(title, onBack: onBack) { EmptyView() }
    }

    init(title: Text?, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack) { EmptyView() }
    }

    init(progress: Double, onBack: (() -> Void)? = nil) {
        self.init(progress: progress, onBack: onBack) { EmptyView() }
    }
}

/// A 28 pt icon button for TKNavBar.
public struct TKNavBarButton: View {
    private let icon: Image
    private let accessibilityLabel: String
    private let action: () -> Void

    @Environment(\.theme) private var theme

    public init(_ icon: Image, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            icon.resizable().scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(theme.colors.textPrimary.color)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
    }
}

/// Figma progress bar: a 12 pt rounded track filled with the brand colour.
public struct TKProgressBar: View {
    private let value: Double
    private let height: CGFloat

    @Environment(\.theme) private var theme

    public init(value: Double, height: CGFloat = 12) {
        self.value = value
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.colors.border.color)
                Capsule()
                    .fill(theme.colors.actionPrimary.color)
                    .frame(width: proxy.size.width * TKProgressBar.clamped(value))
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.25), value: value)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: "\(Int((TKProgressBar.clamped(value) * 100).rounded())) %"))
    }

    nonisolated static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

public extension View {
    /// Hides the system navigation bar and pins a TKNavBar above the content.
    func tkNavigationBar<Trailing: View>(
        _ title: LocalizedStringKey? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        modifier(TKNavBarModifier(bar: TKNavBar(title, onBack: onBack, trailing: trailing)))
    }

    func tkNavigationBar<Trailing: View>(
        progress: Double,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        modifier(TKNavBarModifier(bar: TKNavBar(progress: progress, onBack: onBack, trailing: trailing)))
    }
}

public extension View {
    func tkNavigationBar(_ title: LocalizedStringKey? = nil, onBack: (() -> Void)? = nil) -> some View {
        tkNavigationBar(title, onBack: onBack) { EmptyView() }
    }

    func tkNavigationBar(progress: Double, onBack: (() -> Void)? = nil) -> some View {
        tkNavigationBar(progress: progress, onBack: onBack) { EmptyView() }
    }
}

private struct TKNavBarModifier<Trailing: View>: ViewModifier {
    let bar: TKNavBar<Trailing>
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                bar.background(theme.colors.surfaceBackground.color.ignoresSafeArea(edges: .top))
            }
    }
}
