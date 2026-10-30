import SnapshotTesting
import SwiftUI
import TitanDesignSystem
import XCTest

extension XCTestCase {
    /// Images of `content` on the page background, in light and in dark, at a fixed width and
    /// scale so they don't depend on the simulator. A full screen passes `height` and
    /// `padded: false`; a component gets a margin around it.
    @MainActor
    func snapshot<Content: View>(
        width: CGFloat,
        height: CGFloat? = nil,
        padded: Bool = true,
        locale: Locale = Locale(identifier: "en"),
        dynamicTypeSize: DynamicTypeSize = .large,
        theme: Theme = .base,
        @ViewBuilder content: () -> Content,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        TKFonts.registerBundledFonts()
        let view = content()
        for scheme in [ColorScheme.light, .dark] {
            let page = SnapshotPage(scheme: scheme, locale: locale, dynamicTypeSize: dynamicTypeSize, padded: padded,
                                    theme: theme) { view }
                .frame(width: width, height: height)
            let traits = UITraitCollection(traitsFrom: [
                UITraitCollection(displayScale: 2),
                UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light),
            ])
            withSnapshotTesting(record: snapshotRecordMode) {
                assertSnapshot(
                    of: page,
                    as: .image(precision: 0.99, perceptualPrecision: 0.98, layout: .sizeThatFits, traits: traits),
                    named: scheme == .dark ? "dark" : "light",
                    file: file,
                    testName: testName,
                    line: line
                )
            }
        }
    }
}

/// SNAPSHOT_RECORD=1 rewrites every image; otherwise only missing ones are recorded (and fail).
private var snapshotRecordMode: SnapshotTestingConfiguration.Record {
    ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" ? .all : .missing
}

/// The kit's base theme and page background around a component or screen.
private struct SnapshotPage<Content: View>: View {
    let scheme: ColorScheme
    let locale: Locale
    let dynamicTypeSize: DynamicTypeSize
    let padded: Bool
    let theme: Theme
    @ViewBuilder let content: Content

    var body: some View {
        ThemedPage(padded: padded) { content }
            .titanTheme(theme)
            .environment(\.colorScheme, scheme)
            .environment(\.locale, locale)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
    }
}

private struct ThemedPage<Content: View>: View {
    let padded: Bool
    @ViewBuilder let content: Content
    @Environment(\.theme) private var theme

    var body: some View {
        content
            .padding(padded ? Spacing.lg : 0)
            .background(theme.colors.surfaceBackground.color)
    }
}
