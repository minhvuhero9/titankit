import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization
import TitanPurchase

/// The paywall: a crown, a title, one plan card per product, then the lines App Review asks for
/// (trial and price after it, auto-renewal and how to cancel, Restore, Terms and Privacy).
/// The close button is always visible.
///
///     PaywallScreen(purchase: container.purchase, config: PaywallConfig(...),
///                   benefits: [Text("Không quảng cáo"), Text("Học offline")],
///                   onClose: { router.dismiss() }, onPurchased: { router.dismiss() })
public struct PaywallScreen: View {
    private let config: PaywallConfig
    private let title: Text?
    private let message: Text?
    private let benefits: [Text]
    private let onClose: () -> Void
    private let onPurchased: () -> Void

    @StateObject private var viewModel: PaywallViewModel
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    /// - Parameters:
    ///   - title: "Nâng cấp lên Premium" by default.
    ///   - message: line under the title; the kit's by default.
    ///   - benefits: what premium unlocks, one line each, listed on every plan card.
    ///   - onPurchased: after a purchase or a restore that gives premium.
    public init(
        purchase: any PurchaseService,
        config: PaywallConfig,
        title: Text? = nil,
        message: Text? = nil,
        benefits: [Text],
        onClose: @escaping () -> Void,
        onPurchased: @escaping () -> Void
    ) {
        self.config = config
        self.title = title
        self.message = message
        self.benefits = benefits
        self.onClose = onClose
        self.onPurchased = onPurchased
        _viewModel = StateObject(wrappedValue: PaywallViewModel(purchase: purchase, productIds: config.productIds))
    }

    public var body: some View {
        VStack(spacing: 0) {
            TKNavBar(title: nil) {
                TKNavBarButton(Image(tk: TKSymbol.multiply),
                               accessibilityLabel: KitStrings.string(KitStrings.Paywall.close, locale: locale),
                               action: onClose)
            }
            TKAsyncContent(viewModel.state, retry: { Task { await viewModel.load() } }) { products in
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        header
                        ForEach(products) { product in
                            plan(product)
                        }
                        footer(products)
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkToast($toast)
        .task { await viewModel.load() }
        .task { await viewModel.observeEntitlements() }
        .onChange(of: viewModel.errorKey) { key in
            if let key { toast = TKToast(KitStrings.string(key, locale: locale), style: .error) }
        }
        .onChange(of: viewModel.noticeKey) { key in
            if let key { toast = TKToast(KitStrings.string(key, locale: locale), style: .info) }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(tk: TKSymbol.crown)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(theme.colors.actionOnPrimary.color)
                .frame(width: 80, height: 80)
                .background(theme.gradientPrimary.linearGradient, in: Circle())
                .accessibilityHidden(true)
            (title ?? kit(KitStrings.Paywall.title))
                .font(theme.typography.font(size: 28, weight: .bold, relativeTo: .title1))
                .foregroundStyle(theme.colors.textPrimary.color)
                .accessibilityAddTraits(.isHeader)
            (message ?? kit(KitStrings.Paywall.message))
                .font(theme.typography.font(size: 18, weight: .regular, relativeTo: .body))
                .foregroundStyle(theme.colors.textSecondary.color)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func plan(_ product: StoreProduct) -> some View {
        VStack(spacing: Spacing.xs) {
            TKPlanCard(
                title: Text(verbatim: product.displayName),
                price: Text(verbatim: product.displayPrice),
                period: periodKey(product.subscriptionPeriod).map { kit($0) },
                benefits: benefits,
                badge: product.id == config.highlightedProductId ? kit(KitStrings.Paywall.popular) : nil,
                isCurrent: viewModel.isOwned(product),
                actionTitle: kit(product.freeTrialDays == nil ? KitStrings.Paywall.choose : KitStrings.Paywall.startTrial),
                isLoading: viewModel.purchasingId == product.id
            ) {
                Task {
                    if await viewModel.buy(product) { onPurchased() }
                }
            }
            if let trial = trialLine(product), !viewModel.isOwned(product) {
                Text(verbatim: trial)
                    .font(theme.typography.font(size: 14, weight: .medium, relativeTo: .label))
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func footer(_ products: [StoreProduct]) -> some View {
        VStack(spacing: Spacing.md) {
            if products.contains(where: { $0.kind == .autoRenewable }) {
                kit(KitStrings.Paywall.autoRenew)
                    .font(theme.typography.font(size: 12, weight: .regular, relativeTo: .caption))
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TKButton(kit(KitStrings.Paywall.restore), style: .outline, size: .small, shape: .pill,
                     isLoading: viewModel.isRestoring) {
                Task {
                    if await viewModel.restore() { onPurchased() }
                }
            }
            HStack(spacing: Spacing.lg) {
                link(KitStrings.Settings.terms, url: config.termsURL)
                link(KitStrings.Settings.privacy, url: config.privacyURL)
            }
        }
    }

    private func link(_ key: String, url: URL) -> some View {
        Button { openURL(url) } label: {
            kit(key)
                .font(theme.typography.font(size: 14, weight: .semibold, relativeTo: .label))
                .foregroundStyle(theme.colors.actionPrimary.color)
                .underline()
        }
        .buttonStyle(.plain)
    }

    /// "Miễn phí 7 ngày đầu, sau đó $9.99 / tháng": the price after the trial must be shown.
    private func trialLine(_ product: StoreProduct) -> String? {
        guard let days = product.freeTrialDays else { return nil }
        let period = periodKey(product.subscriptionPeriod).map { KitStrings.string($0, locale: locale) }
        let price = [product.displayPrice, period].compactMap { $0 }.joined(separator: " ")
        return String(format: KitStrings.string(KitStrings.Paywall.trial, locale: locale), days, price)
    }

    private func periodKey(_ period: StoreProduct.Period?) -> String? {
        switch period {
        case .day: KitStrings.Paywall.perDay
        case .week: KitStrings.Paywall.perWeek
        case .month: KitStrings.Paywall.perMonth
        case .year: KitStrings.Paywall.perYear
        case nil: nil
        }
    }

    private func kit(_ key: String) -> Text {
        Text.kit(key, locale: locale)
    }
}
