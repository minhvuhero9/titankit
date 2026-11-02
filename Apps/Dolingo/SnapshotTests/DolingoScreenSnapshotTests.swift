import SnapshotTesting
import SwiftUI
import TitanDesignSystem
import TitanNavigation
import TitanStorage
import XCTest
@testable import Dolingo

/// Dolingo's own screens with the App Store sample learner (`ScreenshotMode`): Vietnamese,
/// 390 × 844, light and dark, and the busiest ones again at a large text size. Compared with
/// the images in __Snapshots__ on every PR; Tools/snapshots.sh records them.
@MainActor
final class DolingoScreenSnapshotTests: XCTestCase {
    func testHome() async { await snapshot(.home) }
    func testChats() async { await snapshot(.chats) }
    func testSpeak() async { await snapshot(.speak) }
    func testProgress() async { await snapshot(.progress) }
    func testLesson() async { await snapshot(.lesson) }
    func testTutor() async { await snapshot(.tutor) }
    func testPaywall() async { await snapshot(.paywall) }

    func testHomeLargeText() async { await snapshot(.home, dynamicTypeSize: .accessibility2, schemes: [.light]) }
    func testLessonLargeText() async { await snapshot(.lesson, dynamicTypeSize: .accessibility2, schemes: [.light]) }
    func testPaywallLargeText() async { await snapshot(.paywall, dynamicTypeSize: .accessibility2, schemes: [.light]) }

    private func snapshot(
        _ screen: ScreenshotMode.Screen,
        dynamicTypeSize: DynamicTypeSize = .large,
        schemes: [ColorScheme] = [.light, .dark],
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) async {
        for scheme in schemes {
            let container = ScreenshotMode.container(for: screen, language: "vi")
            await container.learning.load()
            let traits = UITraitCollection(traitsFrom: [
                UITraitCollection(displayScale: 2),
                UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light),
            ])
            // The screens load their content in `.task` (roleplays, phrases, products): give it
            // a moment before taking the picture.
            let strategy: Snapshotting<SnapshotScreen, UIImage> = .wait(
                for: 1,
                on: .image(precision: 0.99, perceptualPrecision: 0.98,
                           layout: .fixed(width: 390, height: 844), traits: traits)
            )
            let view = SnapshotScreen(container: container, screen: screen, scheme: scheme,
                                      dynamicTypeSize: dynamicTypeSize)
            withSnapshotTesting(record: Self.record) {
                assertSnapshot(of: view, as: strategy, named: scheme == .dark ? "dark" : "light",
                               file: file, testName: testName, line: line)
            }
        }
    }

    /// SNAPSHOT_RECORD=1 rewrites every image; otherwise only missing ones are recorded (and fail).
    private static var record: SnapshotTestingConfiguration.Record {
        ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" ? .all : .missing
    }
}

/// One screen as the app shows it: the tabs for a tab's root, the screen itself for the ones
/// the app presents in a sheet (a sheet isn't part of the picture), with the app's environment.
struct SnapshotScreen: View {
    let container: AppContainer
    let screen: ScreenshotMode.Screen
    var scheme: ColorScheme = .light
    var dynamicTypeSize: DynamicTypeSize = .large

    var body: some View {
        LocalizedRoot(localization: container.localization) {
            content
                .titanTheme(DolingoTheme.theme)
        }
        .environmentObject(container)
        .environment(\.imageCache, container.imageCache)
        .environment(\.colorScheme, scheme)
        .environment(\.dynamicTypeSize, dynamicTypeSize)
    }

    @ViewBuilder
    private var content: some View {
        let router = container.tabs.router(for: .home)
        switch screen {
        case .home, .chats, .speak, .progress:
            MainTabView(container: container, tabs: container.tabs, flow: container.flow, activity: container.activity)
        case .lesson:
            container.makeView(for: .lesson(id: "en.basics.family"), in: router)
        case .tutor:
            container.makeView(for: .tutorChat, in: container.tabs.router(for: .chats))
        case .paywall:
            container.makeView(for: .paywall, in: router)
        }
    }
}
