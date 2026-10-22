import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Shown instead of the app while the backend is under maintenance.
/// The message comes from remote config; empty uses the kit's text.
///
///     case .maintenance(let message):
///         MaintenanceScreen(message: message) { await flow.retryLaunch() }
public struct MaintenanceScreen: View {
    private let message: String
    private let illustration: Image?
    private let onRetry: @MainActor () async -> Void

    @State private var isRetrying = false
    @Environment(\.locale) private var locale

    /// - Parameter illustration: the app's own picture; a gear in a brand circle by default.
    public init(message: String = "", illustration: Image? = nil, onRetry: @escaping @MainActor () async -> Void) {
        self.message = message
        self.illustration = illustration
        self.onRetry = onRetry
    }

    public var body: some View {
        LaunchBlockLayout(
            illustration: illustration ?? Image(tk: .setting, style: .bold),
            title: Text.kit(KitStrings.Launch.maintenanceTitle, locale: locale),
            message: message.isEmpty ? Text.kit(KitStrings.Launch.maintenanceMessage, locale: locale) : Text(verbatim: message)
        ) {
            TKButton(Text.kit(KitStrings.retry, locale: locale), style: .threeD, shape: .pill, isLoading: isRetrying) {
                Task {
                    isRetrying = true
                    await onRetry()
                    isRetrying = false
                }
            }
        }
    }
}

/// Shown instead of the app when its version is below the minimum in remote config.
/// There is no way past it: the only button opens the App Store.
///
///     case .forceUpdate(let url):
///         ForceUpdateScreen(storeURL: url)
public struct ForceUpdateScreen: View {
    private let storeURL: URL
    private let illustration: Image?

    @Environment(\.openURL) private var openURL
    @Environment(\.locale) private var locale

    public init(storeURL: URL, illustration: Image? = nil) {
        self.storeURL = storeURL
        self.illustration = illustration
    }

    public var body: some View {
        LaunchBlockLayout(
            illustration: illustration ?? Image(tk: TKSymbol.autoRenew),
            title: Text.kit(KitStrings.Launch.updateTitle, locale: locale),
            message: Text.kit(KitStrings.Launch.updateMessage, locale: locale)
        ) {
            TKButton(Text.kit(KitStrings.Launch.updateAction, locale: locale), style: .threeD, shape: .pill) {
                openURL(storeURL)
            }
        }
    }
}

/// Picture, title and message in the middle, one button pinned to the bottom.
private struct LaunchBlockLayout<Action: View>: View {
    let illustration: Image
    let title: Text
    let message: Text
    @ViewBuilder let action: Action

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            illustration
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(theme.colors.actionPrimary.color)
                .frame(width: 160, height: 160)
                .background(theme.colors.actionSecondary.color, in: Circle())
                .accessibilityHidden(true)
            VStack(spacing: Spacing.sm) {
                title
                    .font(theme.typography.font(size: 28, weight: .bold, relativeTo: .title1))
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .accessibilityAddTraits(.isHeader)
                message
                    .font(theme.typography.font(size: 18, weight: .regular, relativeTo: .body))
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
            action
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
    }
}
