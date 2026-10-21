import SwiftUI
import TitanIcons

/// One tab of TKTabBar. The icon is drawn light when idle and bold when selected, like the Figma "Menu Bar".
public struct TKTabItem<Tab: Hashable>: Identifiable {
    public let tab: Tab
    public let title: Text
    public let icon: TKIcon

    public var id: Tab { tab }

    public init(_ tab: Tab, title: LocalizedStringKey, icon: TKIcon) {
        self.init(tab, title: Text(title), icon: icon)
    }

    public init(_ tab: Tab, title: Text, icon: TKIcon) {
        self.tab = tab
        self.title = title
        self.icon = icon
    }
}

/// Figma "Menu Bar": the bottom tab bar. Put it under the content with `safeAreaInset`:
///
///     content
///         .safeAreaInset(edge: .bottom, spacing: 0) {
///             TKTabBar(selected: tabs.selected, items: items) { tabs.select($0) }
///         }
///
/// `onSelect` also fires for the tab that is already selected, so TabRouter.select can pop it to its root.
public struct TKTabBar<Tab: Hashable>: View {
    private let selected: Tab
    private let items: [TKTabItem<Tab>]
    private let onSelect: (Tab) -> Void

    @Environment(\.theme) private var theme

    public init(selected: Tab, items: [TKTabItem<Tab>], onSelect: @escaping (Tab) -> Void) {
        self.selected = selected
        self.items = items
        self.onSelect = onSelect
    }

    public init(selection: Binding<Tab>, items: [TKTabItem<Tab>]) {
        self.init(selected: selection.wrappedValue, items: items) { selection.wrappedValue = $0 }
    }

    public var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(items) { item in
                let isSelected = item.tab == selected
                Button { onSelect(item.tab) } label: {
                    VStack(spacing: Spacing.xxs) {
                        Image(tk: item.icon, style: isSelected ? .bold : .light)
                            .resizable().scaledToFit()
                            .frame(width: 24, height: 24)
                        item.title
                            .font(theme.typography.font(size: 10, weight: isSelected ? .bold : .medium, relativeTo: .caption))
                            .tracking(0.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle((isSelected ? theme.colors.actionPrimary : theme.colors.textDisabled).color)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xxs)
        .background {
            AdaptiveColor(light: RGBA.white.opacity(0.92), dark: theme.colors.surfaceBackground.dark.opacity(0.92)).color
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}
