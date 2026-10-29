import SwiftUI
import TitanFeatures
import TitanPurchase

/// The kit's paywall with Dolingo's plans and benefits. Shown in a sheet; closes after a purchase.
struct DolingoPaywall: View {
    let purchase: any PurchaseService
    let onDismiss: () -> Void

    var body: some View {
        PaywallScreen(
            purchase: purchase,
            config: AppConfig.paywall,
            benefits: [
                Text("paywall.benefit.noAds"),
                Text("paywall.benefit.unlimited"),
                Text("paywall.benefit.offline"),
            ],
            onClose: onDismiss,
            onPurchased: onDismiss
        )
    }
}
