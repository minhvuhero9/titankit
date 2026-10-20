import SwiftUI
import TitanDesignSystem
import TitanLocalization

public struct SplashConfig {
    /// Logo shown in the middle, drawn in the "on primary" colour.
    public var logo: Image
    public var appName: String
    /// Keeps the splash up at least this long so it doesn't flash.
    public var minimumDuration: Duration

    public init(logo: Image, appName: String, minimumDuration: Duration = .seconds(1)) {
        self.logo = logo
        self.appName = appName
        self.minimumDuration = minimumDuration
    }
}

/// Brand-coloured launch screen with logo, name and spinner. Runs `prepare` (remote config,
/// session check...) and calls `onFinish` when both it and the minimum duration are done.
public struct SplashScreen: View {
    private let config: SplashConfig
    private let prepare: @MainActor () async -> Void
    private let onFinish: @MainActor () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    public init(
        config: SplashConfig,
        prepare: @escaping @MainActor () async -> Void = {},
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.config = config
        self.prepare = prepare
        self.onFinish = onFinish
    }

    public var body: some View {
        let onPrimary = theme.colors.actionOnPrimary.color
        VStack(spacing: Spacing.lg) {
            Spacer()
            config.logo
                .resizable().scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(onPrimary)
                .accessibilityHidden(true)
            Text(verbatim: config.appName)
                .tkTextStyle(.title1)
                .foregroundStyle(onPrimary)
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(onPrimary)
                .accessibilityLabel(Text.kit(KitStrings.loading, locale: locale))
                .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.actionPrimary.color.ignoresSafeArea())
        .task {
            await SplashTimer.run(minimum: config.minimumDuration, work: prepare)
            onFinish()
        }
    }
}

/// Runs work and a minimum wait side by side; returns when both are done.
enum SplashTimer {
    @MainActor
    static func run(minimum: Duration, work: @MainActor () async -> Void) async {
        let start = ContinuousClock.now
        await work()
        let remaining = minimum - (ContinuousClock.now - start)
        if remaining > .zero {
            try? await Task.sleep(for: remaining)
        }
    }
}
