import SwiftUI
import TitanIcons
import TitanLocalization

/// Figma "Subscriptions Card": one plan on a paywall or the billing screen, with its price,
/// a list of benefits and a button, or "Your current plan" when the user already has it.
///
///     TKPlanCard(title: Text("Dolingo Premium"), price: Text(product.displayPrice),
///                period: Text("/ tháng"), benefits: [Text("Không quảng cáo"), Text("Học offline")],
///                badge: Text("Phổ biến nhất"), actionTitle: Text("Chọn gói")) { buy(product) }
///
/// Prices come from the store (`TitanPurchase`), never typed in the app, so they show in the
/// user's currency.
public struct TKPlanCard: View {
    private let title: Text
    private let price: Text
    private let period: Text?
    private let benefits: [Text]
    private let badge: Text?
    private let isCurrent: Bool
    private let actionTitle: Text?
    private let isLoading: Bool
    private let action: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - badge: shown in the top-right corner, e.g. "Phổ biến nhất".
    ///   - isCurrent: replaces the button with "Gói hiện tại của bạn".
    ///   - isLoading: spinner on the button while a purchase runs.
    public init(
        title: Text,
        price: Text,
        period: Text? = nil,
        benefits: [Text],
        badge: Text? = nil,
        isCurrent: Bool = false,
        actionTitle: Text? = nil,
        isLoading: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.price = price
        self.period = period
        self.benefits = benefits
        self.badge = badge
        self.isCurrent = isCurrent
        self.actionTitle = actionTitle
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                title
                    .font(theme.typography.font(size: 20, weight: .bold, relativeTo: .title3))
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    price
                        .font(theme.typography.font(size: 48, weight: .bold, relativeTo: .display))
                        .minimumScaleFactor(0.6)
                    period?
                        .font(theme.typography.font(size: 18, weight: .semibold, relativeTo: .body))
                }
                .lineLimit(1)
            }
            .foregroundStyle(theme.colors.textPrimary.color)
            .accessibilityElement(children: .combine)
            TKDivider()
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(benefits.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(tk: TKSymbol.check)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .accessibilityHidden(true)
                        benefits[index]
                            .font(theme.typography.font(size: 18, weight: .regular, relativeTo: .body))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(theme.colors.textPrimary.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TKDivider()
            if isCurrent {
                Text.kit(KitStrings.currentPlan, locale: locale)
                    .font(theme.typography.font(size: 20, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(theme.colors.textSecondary.color)
            } else if let actionTitle, let action {
                TKButton(actionTitle, style: .threeD, size: .medium, shape: .pill, isLoading: isLoading, action: action)
            }
        }
        .padding(Spacing.lg)
        .overlay(alignment: .topTrailing) {
            if let badge {
                badge
                    .font(theme.typography.font(size: 16, weight: .medium, relativeTo: .callout))
                    .foregroundStyle(theme.colors.actionOnPrimary.color)
                    .padding(.vertical, Spacing.xxs)
                    .padding(.horizontal, 10)
                    .background(theme.colors.actionPrimary.color, in: TKBadgeCornerShape(radius: 10))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .tkOutlinedCard(isSelected: isCurrent)
    }
}

/// Only the bottom-left corner is rounded, so the badge tucks into the card's top-right corner.
private struct TKBadgeCornerShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.minX, y: rect.maxY - radius), radius: radius)
        path.closeSubpath()
        return path
    }
}

/// Figma "Upgrade Subscription Banner": the brand-coloured call to upgrade at the top of Settings.
///
///     TKUpgradeBanner(title: Text("Nâng cấp ngay!"), message: Text("Mở khoá mọi bài học")) { showPaywall() }
public struct TKUpgradeBanner: View {
    private let title: Text
    private let message: Text?
    private let icon: Image
    private let action: () -> Void

    @Environment(\.theme) private var theme

    /// - Parameter icon: drawn in the white circle; a crown by default.
    public init(title: Text, message: Text? = nil, icon: Image = Image(tk: TKSymbol.crown), action: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                icon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(theme.colors.actionPrimary.color)
                    .frame(width: 48, height: 48)
                    .background(theme.colors.actionOnPrimary.color, in: Circle())
                    .padding(6)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    title
                        .font(theme.typography.font(size: 18, weight: .bold, relativeTo: .headline))
                    message?
                        .font(theme.typography.font(size: 12, weight: .regular, relativeTo: .caption))
                }
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(EdgeInsets(top: Spacing.sm, leading: Spacing.sm, bottom: Spacing.sm, trailing: Spacing.md))
            .background {
                ZStack {
                    shape.fill(theme.colors.actionPrimaryPressed.color).offset(y: 5)
                    shape.fill(theme.gradientPrimary.linearGradient)
                }
            }
            .padding(.bottom, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
