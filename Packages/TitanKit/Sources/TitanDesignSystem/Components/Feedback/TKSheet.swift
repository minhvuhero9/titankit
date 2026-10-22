import SwiftUI

/// Figma bottom sheet ("Choose Theme", "Logout"): a centred title, the content between two
/// dividers, then Cancel and OK side by side. Show it with `.tkSheet(isPresented:)`.
///
///     .tkSheet(isPresented: $choosing) {
///         TKSheet(title: Text("Chọn chủ đề"),
///                 primary: .init("OK") { apply() },
///                 secondary: .init("Huỷ") { choosing = false }) {
///             TKRadioGroup(selection: $draft, options: options)
///         }
///     }
public struct TKSheet<Content: View>: View {
    private let title: Text
    private let titleColor: Color?
    private let primary: TKModalAction
    private let secondary: TKModalAction?
    private let content: Content

    @Environment(\.theme) private var theme

    /// - Parameters:
    ///   - titleColor: e.g. the error colour for "Đăng xuất". Text colour by default.
    ///   - secondary: soft button on the left, usually Cancel.
    public init(
        title: Text,
        titleColor: Color? = nil,
        primary: TKModalAction,
        secondary: TKModalAction? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleColor = titleColor
        self.primary = primary
        self.secondary = secondary
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            title
                .font(theme.typography.font(size: 24, weight: .bold, relativeTo: .title2))
                .foregroundStyle(titleColor ?? theme.colors.textPrimary.color)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            TKDivider()
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            TKDivider()
            HStack(spacing: Spacing.sm) {
                if let secondary {
                    TKButton(secondary.title, style: .light, size: .medium, shape: .pill, action: secondary.action)
                }
                TKButton(primary.title, style: .threeD, size: .medium, shape: .pill, action: primary.action)
            }
        }
        .padding(EdgeInsets(top: Spacing.xl, leading: Spacing.lg, bottom: Spacing.lg, trailing: Spacing.lg))
        .frame(maxWidth: .infinity)
    }
}

public extension TKSheet where Content == EmptyView {
    /// A sheet with only a title, e.g. a confirmation.
    init(title: Text, titleColor: Color? = nil, primary: TKModalAction, secondary: TKModalAction? = nil) {
        self.init(title: title, titleColor: titleColor, primary: primary, secondary: secondary) { EmptyView() }
    }
}

public extension View {
    /// Presents `content` as a bottom sheet that is exactly as tall as the content.
    func tkSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented) {
            FittedSheet(content: content)
        }
    }
}

private struct FittedSheet<Content: View>: View {
    let content: () -> Content
    @State private var height: CGFloat = 320
    @Environment(\.theme) private var theme

    var body: some View {
        content()
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
                }
            }
            .onPreferenceChange(SheetHeightKey.self) { value in
                if value > 0 { height = value }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(theme.colors.surfaceCard.color.ignoresSafeArea())
            .presentationDetents([.height(height)])
            .presentationDragIndicator(.visible)
    }
}

private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
