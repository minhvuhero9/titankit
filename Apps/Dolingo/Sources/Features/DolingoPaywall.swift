import SwiftUI
import TitanFeatures
import TitanPurchase

/// The kit paywall with Dolingo's benefits; after buying or restoring Premium it turns into
/// Figma "upgrade plan subscription successful".
struct DolingoPaywall: View {
    let purchase: any PurchaseService
    let onDismiss: () -> Void

    @State private var isPremium = false

    /// What Premium unlocks in Dolingo today, on the paywall and again after buying.
    static var benefits: [Text] {
        [
            Text("premium.benefit.lessons"),
            Text("premium.benefit.roleplays"),
            Text("premium.benefit.topics"),
            Text("premium.benefit.createRoleplay"),
        ]
    }

    var body: some View {
        if isPremium {
            PremiumWelcomeScreen(
                message: Text("premium.welcome.message"),
                benefits: Self.benefits,
                footnote: Text("premium.welcome.footnote"),
                actionTitle: Text("premium.welcome.action"),
                action: onDismiss
            )
            .transition(.opacity)
        } else {
            PaywallScreen(
                purchase: purchase,
                config: AppConfig.paywall,
                planTitle: Text(verbatim: "Dolingo Premium"),
                benefits: Self.benefits,
                onClose: onDismiss,
                onPurchased: { withAnimation { isPremium = true } }
            )
        }
    }
}
