import SnapshotTesting
import SwiftUI
import TitanDesignSystem
import TitanIcons
import XCTest

/// Pictures of the design system's components in light and dark, compared with the images in
/// __Snapshots__ so a change that breaks how a component looks fails the build.
///
/// A new or changed component needs its images recorded: run the Snapshots workflow with
/// "record" (it commits the images to the branch), or run the tests on a Mac with
/// SNAPSHOT_RECORD=1 in the test plan's environment and commit __Snapshots__.
@MainActor
final class ComponentSnapshotTests: XCTestCase {
    func testButtons() {
        snapshot(width: 360) {
            VStack(spacing: Spacing.md) {
                ForEach(TKButton.Style.allCases, id: \.self) { style in
                    TKButton(Text(verbatim: style.rawValue.capitalized), style: style) {}
                }
                TKButton(Text(verbatim: "Loading"), isLoading: true) {}
                TKButton(Text(verbatim: "Disabled")) {}
                    .disabled(true)
                HStack {
                    ForEach(TKButton.Size.allCases, id: \.self) { size in
                        TKButton(Text(verbatim: "Go"), size: size, fullWidth: false) {}
                    }
                }
            }
        }
    }

    func testTextFields() {
        snapshot(width: 360) {
            VStack(spacing: Spacing.lg) {
                TKTextField(label: Text(verbatim: "Email"), text: .constant(""), prompt: Text(verbatim: "you@example.com"),
                            icon: Image(tk: TKIcon.message))
                TKTextField(label: Text(verbatim: "Email"), text: .constant("minh@dolingo.app"), icon: Image(tk: TKIcon.message),
                            status: .success("Looks good"))
                TKTextField(label: Text(verbatim: "Password"), text: .constant("secret"), icon: Image(tk: TKIcon.lock),
                            status: .error("At least 8 characters"), kind: .secure)
                TKTextField(label: Text(verbatim: "Name"), text: .constant("Minh"))
                    .tkFieldStyle(.underlined)
            }
        }
    }

    func testPlanCard() {
        snapshot(width: 360) {
            TKPlanCard(
                title: Text(verbatim: "Dolingo Premium"),
                price: Text(verbatim: "$4.99"),
                period: Text(verbatim: "/ month"),
                benefits: [Text(verbatim: "Every lesson and roleplay"), Text(verbatim: "Unlimited AI roleplays")],
                badge: Text(verbatim: "Save 17%")
            )
        }
    }

    func testTabsAndCodeField() {
        snapshot(width: 360) {
            VStack(spacing: Spacing.xl) {
                TKSegmentedTabs(selection: .constant(1), options: [
                    TKOption(0, title: Text(verbatim: "Monthly")),
                    TKOption(1, title: Text(verbatim: "Yearly")),
                ])
                TKUnderlineTabs(selection: .constant(0), options: [
                    TKOption(0, title: Text(verbatim: "Lessons")),
                    TKOption(1, title: Text(verbatim: "Words")),
                ])
                TKCodeField(code: .constant("12"), length: 4)
                TKCodeField(code: .constant("1234"), length: 4, isError: true)
            }
        }
    }

    func testSettingsRowsAndEmptyState() {
        snapshot(width: 360) {
            VStack(spacing: Spacing.lg) {
                TKSettingsRow(title: Text(verbatim: "Notifications"), icon: Image(tk: TKIcon.notification)) {}
                TKSettingsRow(title: Text(verbatim: "Delete account"), icon: Image(tk: TKIcon.delete), role: .destructive) {}
                TKEmptyState(icon: Image(tk: TKIcon.document), title: "Nothing here yet", message: "Saved phrases show up here.")
            }
        }
    }

    /// Large accessibility text: labels wrap and controls grow instead of clipping. With a
    /// bundled font family, as the apps use: the base theme's system font follows the device
    /// setting rather than the view's `dynamicTypeSize`.
    func testLargeDynamicType() {
        let theme = Theme.base.merged(with: ThemePatch(fontFamily: TKFonts.urbanist))
        snapshot(width: 360, dynamicTypeSize: .accessibility3, theme: theme) {
            VStack(spacing: Spacing.md) {
                TKButton(Text(verbatim: "Continue with email")) {}
                TKTextField(label: Text(verbatim: "Email"), text: .constant("minh@dolingo.app"), icon: Image(tk: TKIcon.message))
                TKSettingsRow(title: Text(verbatim: "Notifications"), icon: Image(tk: TKIcon.notification)) {}
            }
        }
    }
}
