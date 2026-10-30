import SwiftUI
import TitanAuth
import TitanDesignSystem
import TitanFeatures
import TitanIcons
import XCTest

/// The kit's ready-made screens at iPhone size (390 × 844), in Vietnamese, light and dark.
/// Only screens that draw everything on their first frame: a screen that loads first (the
/// paywall) would be pictured mid-load.
@MainActor
final class ScreenSnapshotTests: XCTestCase {
    private let vietnamese = Locale(identifier: "vi")

    func testOnboarding() {
        screen {
            OnboardingScreen(
                config: OnboardingConfig(pages: [
                    OnboardingPage(image: Image(systemName: "graduationcap.fill"),
                                   title: "Học tiếng Anh mỗi ngày", message: "Bài ngắn, luyện nói và gia sư AI."),
                ]),
                onGetStarted: {},
                onSignIn: {}
            )
        }
    }

    func testLogin() {
        screen {
            LoginScreen(
                config: LoginConfig(socialOptions: [
                    SocialLoginOption(.google, icon: Image(systemName: "g.circle.fill"), accessibilityLabel: "Google"),
                    SocialLoginOption(.apple, icon: Image(systemName: "apple.logo"), accessibilityLabel: "Apple"),
                ]),
                auth: MockAuthService(),
                onSuccess: { _ in }
            )
        }
    }

    func testSignUp() {
        screen {
            SignUpScreen(auth: MockAuthService(), onExit: {}, onSuccess: { _ in })
        }
    }

    func testPasswordReset() {
        screen {
            NavigationStack {
                PasswordResetScreen(auth: MockAuthService(), email: "minh@dolingo.app", onExit: {}, onSignedIn: { _ in })
            }
        }
    }

    func testSuccess() {
        screen {
            SuccessScreen(title: Text(verbatim: "Hoàn tất!"), message: Text(verbatim: "Lộ trình học của bạn đã sẵn sàng."),
                          actionTitle: Text(verbatim: "Bắt đầu")) {}
        }
    }

    func testPremiumWelcome() {
        screen {
            PremiumWelcomeScreen(
                message: Text(verbatim: "Cảm ơn bạn đã nâng cấp."),
                benefits: [Text(verbatim: "Mọi bài học và roleplay"), Text(verbatim: "Tạo roleplay bằng AI không giới hạn")],
                actionTitle: Text(verbatim: "Học tiếp")
            ) {}
        }
    }

    func testSettings() {
        screen {
            NavigationStack {
                SettingsScreen(
                    sections: [
                        SettingsSection(items: [
                            SettingsItem("profile", title: Text(verbatim: "Thông tin cá nhân"), icon: Image(tk: TKIcon.profile)),
                            SettingsItem("notifications", title: Text(verbatim: "Thông báo"), icon: Image(tk: TKIcon.notification)),
                        ]),
                        SettingsSection(items: [
                            SettingsItem("help", title: Text(verbatim: "Trợ giúp"), icon: Image(tk: TKIcon.document)),
                        ]),
                    ],
                    onSelect: { _ in },
                    onLogout: {}
                )
            }
        }
    }

    func testDeleteAccount() {
        screen {
            NavigationStack {
                DeleteAccountScreen(auth: MockAuthService(), onBack: {}, onDeleted: {})
            }
        }
    }

    func testMaintenance() {
        screen {
            MaintenanceScreen(message: "Dolingo đang bảo trì, quay lại sau ít phút nhé.") {}
        }
    }

    func testForceUpdate() throws {
        let store = try XCTUnwrap(URL(string: "https://apps.apple.com/app/id0000000000"))
        screen {
            ForceUpdateScreen(storeURL: store)
        }
    }

    private func screen<Content: View>(
        @ViewBuilder content: () -> Content,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        snapshot(width: 390, height: 844, padded: false, locale: vietnamese, content: content,
                 file: file, testName: testName, line: line)
    }
}
