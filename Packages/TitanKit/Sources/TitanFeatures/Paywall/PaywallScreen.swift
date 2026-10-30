import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization
import TitanPurchase

/// Figma "upgrade plan": "Monthly / Yearly" tabs, one plan card with the price and what premium
/// unlocks (and "Save 17%" on the yearly plan), then the lines App Review asks for (trial and
/// price after it, auto-renewal and how to cancel, Restore, Terms and Privacy), and a fixed
/// "Continue - $4.99" button. The back button closes it.
///
///     PaywallScreen(purchase: container.purchase, config: PaywallConfig(...),
///                   planTitle: Text("Dolingo Premium"),
///                   benefits: [Text("Không quảng cáo"), Text("Học offline")],
///                   onClose: { router.dismiss() }, onPurchased: { router.dismiss() })
public struct PaywallScreen: View {
    private let config: PaywallConfig
    private let title: Text?
    private let planTitle: Text?
    private let benefits: [Text]
    private let onClose: () -> Void
    private let onPurchased: () -> Void

    @StateObject private var viewModel: PaywallViewModel
    @State private var selectedId: String?
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL

    /// - Parameters:
    ///   - title: the bar's title, "Nâng cấp gói" by default.
    ///   - planTitle: on the card, e.g. "Dolingo Premium"; the product's name by default.
    ///   - benefits: what premium unlocks, one line each.
    ///   - onPurchased: after a purchase or a restore that gives premium.
    public init(
        purchase: any PurchaseService,
        config: PaywallConfig,
        title: Text? = nil,
        planTitle: Text? = nil,
        benefits: [Text],
        onClose: @escaping () -> Void,
        onPurchased: @escaping () -> Void
    ) {
        self.config = config
        self.title = title
        self.planTitle = planTitle
        self.benefits = benefits
        self.onClose = onClose
        self.onPurchased = onPurchased
        _viewModel = StateObject(wrappedValue: PaywallViewModel(purchase: purchase, productIds: config.productIds))
    }

    public var body: some View {
        TKAsyncContent(viewModel.state, retry: { Task { await viewModel.load() } }) { products in
            let product = selected(in: products)
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        if products.count > 1 {
                            TKSegmentedTabs(selection: selection(products), options: products.map {
                                TKOption($0.id, title: tabTitle($0))
                            })
                        }
                        plan(product, in: products)
                        footer(product, products)
                    }
                    .padding(Spacing.lg)
                }
                continueBar(product)
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: title ?? kit(KitStrings.Paywall.upgradePlan), onBack: onClose)
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

    /// The tab the user picked, else the highlighted plan, else the first.
    private func selected(in products: [StoreProduct]) -> StoreProduct {
        products.first { $0.id == selectedId }
            ?? products.first { $0.id == config.highlightedProductId }
            ?? products[0]
    }

    private func selection(_ products: [StoreProduct]) -> Binding<String> {
        Binding(get: { selected(in: products).id }, set: { selectedId = $0 })
    }

    private func tabTitle(_ product: StoreProduct) -> Text {
        switch product.subscriptionPeriod {
        case .month: kit(KitStrings.Paywall.monthly)
        case .year: kit(KitStrings.Paywall.yearly)
        default: Text(verbatim: product.displayName)
        }
    }

    private func plan(_ product: StoreProduct, in products: [StoreProduct]) -> some View {
        TKPlanCard(
            title: planTitle ?? Text(verbatim: product.displayName),
            price: Text(verbatim: product.displayPrice),
            period: periodKey(product.subscriptionPeriod).map { kit($0) },
            benefits: benefits,
            badge: badge(product, in: products),
            isCurrent: viewModel.isOwned(product)
        )
    }

    /// "Tiết kiệm 17%" on a yearly plan, else "Phổ biến nhất" on the highlighted one.
    private func badge(_ product: StoreProduct, in products: [StoreProduct]) -> Text? {
        if let percent = PaywallViewModel.savingsPercent(of: product, in: products) {
            return Text(verbatim: String(format: KitStrings.string(KitStrings.Paywall.save, locale: locale), percent))
        }
        return product.id == config.highlightedProductId ? kit(KitStrings.Paywall.popular) : nil
    }

    /// "Tiếp tục - $4.99", or "Dùng thử miễn phí" for a plan with a trial.
    private func continueBar(_ product: StoreProduct) -> some View {
        VStack(spacing: Spacing.sm) {
            Divider()
            TKButton(continueTitle(product), style: .threeD, shape: .pill,
                     isLoading: viewModel.purchasingId == product.id) {
                Task {
                    if await viewModel.buy(product) { onPurchased() }
                }
            }
            .disabled(viewModel.isOwned(product) || viewModel.isBusy)
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.bottom, Spacing.sm)
        .background(theme.colors.surfaceCard.color.ignoresSafeArea(edges: .bottom))
    }

    private func continueTitle(_ product: StoreProduct) -> Text {
        if viewModel.isOwned(product) { return kit(KitStrings.currentPlan) }
        if product.freeTrialDays != nil { return kit(KitStrings.Paywall.startTrial) }
        return Text(verbatim: String(format: KitStrings.string(KitStrings.Paywall.continuePrice, locale: locale),
                                     product.displayPrice))
    }

    private func footer(_ product: StoreProduct, _ products: [StoreProduct]) -> some View {
        VStack(spacing: Spacing.md) {
            if let trial = trialLine(product), !viewModel.isOwned(product) {
                Text(verbatim: trial)
                    .font(theme.typography.font(size: 14, weight: .medium, relativeTo: .label))
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            if products.contains(where: { $0.kind == .autoRenewable }) {
                kit(KitStrings.Paywall.autoRenew)
                    .font(theme.typography.font(size: 12, weight: .regular, relativeTo: .caption))
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            TKButton(kit(KitStrings.Paywall.restore), style: .outline, size: .small, shape: .pill,
                     isLoading: viewModel.isRestoring) {
                Task {
                    if await viewModel.restore() { onPurchased() }
                }
            }
            .disabled(viewModel.isBusy)
            HStack(spacing: Spacing.lg) {
                link(KitStrings.Settings.terms, url: config.termsURL)
                link(KitStrings.Settings.privacy, url: config.privacyURL)
            }
        }
        .multilineTextAlignment(.center)
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
