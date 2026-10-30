# Kế hoạch làm App 1

[← Về tổng quan](README.md)

App 1 là app đầu tiên dựng trên TitanKit. Kit và App 1 được làm song song: mỗi phần kit được viết ra vì App 1 cần nó, rồi App 1 dùng ngay. Kế hoạch chia 7 giai đoạn (0 đến 6). Giai đoạn sau dựa vào giai đoạn trước, nhưng một số việc có thể chạy song song (ví dụ giai đoạn 2 và 4).

## Câu hỏi còn mở

Cần trả lời trước hoặc trong giai đoạn 0:

| # | Câu hỏi | Ảnh hưởng tới |
| --- | --- | --- |
| 1 | Tên chính thức của App 1? | Thư mục app, theme `<AppName>Theme`, bundle id |
| 2 | Link Figma của App 1? | Giai đoạn 2 và 5 |
| 3 | Tên công ty trong bundle id `com.<company>.<app>`? | Giai đoạn 0, Apple Developer, Firebase |
| 4 | App 1 cần dịch vụ nào: đăng nhập, mua trong app, quảng cáo, push, analytics? | Giai đoạn 4, module nào được bật |
| 5 | Ai có quyền ghi vào repo và tài khoản Apple Developer / Firebase? | Giai đoạn 0 |

## Giai đoạn 0: Repo, Tuist, CI

**Mục tiêu:** có repo build được một app trống trên CI.

- [ ] Tạo repo `titankit` theo cấu trúc ở [README mục 7](README.md#7-cấu-trúc-repo).
- [ ] Tạo `Packages/TitanKit/Package.swift` với các module rỗng.
- [ ] Cấu hình Tuist (`Project.swift`, `Tuist/`) và `Templates/NewApp`.
- [ ] Tạo App1 từ mẫu, với `Dev`, `Staging`, `Prod` xcconfig và `Secrets.xcconfig` ngoài git.
- [ ] Thêm `.swiftlint.yml`, `CHANGELOG.md`, `.gitignore`.
- [ ] Thiết lập fastlane (`test`, `beta`) và `fastlane match`.
- [ ] Thêm GitHub Actions chạy lint + test cho mỗi PR.
- [ ] Đăng ký bundle id và app trên App Store Connect.

**Xong khi:** PR đầu tiên chạy CI xanh; `tuist generate App1` mở được app trống trên simulator.

**Đọc:** [Tooling.md](modules/Tooling.md), [Conventions.md](Conventions.md).

## Giai đoạn 1: Module nền tảng

**Mục tiêu:** có lớp nền mà mọi module khác dựa vào.

- [x] TitanCore: logger, `LoadState`, lỗi chung, `AppEnvironment`, tiện ích.
- [x] TitanNetworking: `Endpoint`, client async, interceptor (token, retry, log), theo dõi mất mạng.
- [x] TitanStorage: UserDefaults có kiểu, Keychain, cache file, cache ảnh.
- [x] Bản Mock cho mọi protocol.
- [x] `AppContainer.swift` của App1 tạo các service nền.

**Xong khi:** các module có unit test chạy trên CI; App1 gọi được một API mẫu qua Networking.

**Thực tế:** làm trong PR #2. API mẫu là `AppStatusRepository` (`GET /v1/app-status`), hiện được test bằng `MockAPIClient` vì backend chưa có.

**Đọc:** [Core.md](modules/Core.md), [Networking.md](modules/Networking.md), [Storage.md](modules/Storage.md).

## Giai đoạn 2: Design system

**Mục tiêu:** có base theme và component, sau đó áp token Figma của App 1.

- [x] Định nghĩa token semantic (màu, chữ, khoảng cách, bo góc). Bóng làm cùng component.
- [x] Base theme sáng và tối.
- [x] Component `TK*` cơ bản: Button, TextField, Card, Toast, Loading, EmptyState, ErrorView, AsyncContent. List row và Sheet làm khi màn hình cần.
- [x] Trang Catalog (`TKCatalogView`) hiển thị mọi component với theme của app; Dolingo mở từ màn hình đầu.
- [ ] Snapshot test cho từng component (hiện có unit test cho màu và trạng thái; snapshot cần thêm thư viện, để sau).
- [x] Lấy token Figma của App 1, tạo `DolingoTheme` (chép tay; `gen-tokens` để sau).

**Xong khi:** Catalog chạy được với base theme và `App1Theme`; snapshot test xanh.

**Đọc:** [DesignSystem.md](modules/DesignSystem.md), [Tooling.md](modules/Tooling.md#sinh-token-từ-figma).

## Giai đoạn 3: Điều hướng và màn hình dựng sẵn

**Mục tiêu:** App 1 chạy được luồng Splash → Onboarding → Login → Home (Home tạm) với Mock.

- [x] TitanNavigation: `Route`, Router, tab, sheet, deep link.
- [x] TitanLocalization: catalog kit, đổi ngôn ngữ, formatter.
- [x] TitanFeatures: Splash, Onboarding, Login, Settings, App Appearance, WebPage, Maintenance, Force update, Profile, Delete account.
- [x] Rate app prompt (`RatePromptState`, `tkRequestReview`).
- [x] Paywall (`PaywallScreen`, `PaywallViewModel`); Dolingo mở từ Cài đặt và `dolingo://premium`.
- [ ] Mỗi màn hình có trang Catalog và snapshot test.
- [ ] Nối các màn hình vào Router của App 1 bằng `Config` và callback.

**Xong khi:** đi hết luồng chính trên simulator với service Mock, ở cả `vi` và `en`, sáng và tối.

**Đọc:** [Navigation.md](modules/Navigation.md), [Features.md](modules/Features.md), [Localization.md](modules/Localization.md).

## Giai đoạn 4: Dịch vụ qua adapter Firebase

**Mục tiêu:** thay Mock bằng dịch vụ thật cho những gì App 1 cần (xem câu hỏi 4).

- [ ] Tạo project Firebase cho Dev, Staging, Prod (việc của chủ tài khoản, xem [Firebase-Setup.md](Firebase-Setup.md)).
- [x] `Adapters/TitanFirebase`: Core, Auth (email, Apple, Google, khách), Remote Config, Analytics + Crashlytics. Firestore và Messaging chưa cần.
- [x] TitanAuth: `AppleSignInHelper`, `idToken`, xóa tài khoản; `GoogleSignInHelper` nằm trong adapter vì cần SDK Google.
- [x] TitanRemoteConfig: adapter Firebase cho `LaunchChecker`.
- [x] TitanAnalytics: `AnalyticsService`, `CrashService`, sự kiện chung, Composite, Console, NoOp, Spy; màn Dữ liệu & Phân tích.
- [x] TitanPurchase: `PurchaseService`, adapter StoreKit 2 và Mock (chưa có RevenueCat); `Dolingo.storekit` để mua thử trong Xcode.
- [ ] TitanAds (AdMob + UMP), TitanPush nếu cần.
- [x] `AppContainer` dùng Firebase khi có `GoogleService-Info-<Env>.plist`, không có thì chạy Mock.
- [x] Server AI kiểm tra token Firebase và giới hạn lượt mỗi ngày theo tài khoản.
- [x] Liên kết tài khoản (màn 99): Google, Apple; tài khoản khách liên kết để giữ tiến độ.
- [ ] Đăng nhập Facebook, Twitter và các cách khác: tạm hoãn, chỉ dùng email, Apple, Google.

**Xong khi:** App1-Staging đăng nhập thật, đọc Remote Config thật, sự kiện analytics hiện trên console.

**Đọc:** [Backend.md](modules/Backend.md), [Auth.md](modules/Auth.md), [RemoteConfig.md](modules/RemoteConfig.md), [Analytics.md](modules/Analytics.md), [Purchase.md](modules/Purchase.md), [Ads.md](modules/Ads.md), [Push.md](modules/Push.md).

## Giai đoạn 5: Màn hình riêng của App 1

**Mục tiêu:** làm phần nghiệp vụ riêng theo Figma của App 1.

- [x] Liệt kê màn hình riêng từ Figma ([Dolingo-Screens.md](Dolingo-Screens.md)).
- [x] Đăng ký: 10 câu hỏi, chuẩn bị lộ trình, tạo tài khoản (màn 5–20).
- [ ] Định nghĩa model và Repository của App 1 (ví dụ `UserRepository`).
- [ ] Viết View + ViewModel cho từng màn trong `Apps/App1/Sources/Features/`.
- [ ] Unit test ViewModel với Repository Mock.
- [ ] Xử lý loading, lỗi, rỗng, mất mạng bằng `StateView`.
- [ ] Component nào dùng lại được cho app khác thì chuyển vào kit (PR `kit/...`).

**Xong khi:** mọi màn hình trong Figma có trên App1-Staging, khớp design, test xanh.

**Đọc:** [README mục 4](README.md#4-kiến-trúc-bên-trong-một-app), [Conventions.md](Conventions.md).

## Giai đoạn 6: Compliance và TestFlight

**Mục tiêu:** bản App 1 đủ điều kiện review, có trên TestFlight.

- [x] `PrivacyInfo.xcprivacy` của Dolingo và câu trả lời nhãn App Privacy ([AppStore-Dolingo.md](AppStore-Dolingo.md)). Còn kiểm tra Privacy Report trên bản archive.
- [x] Không cần ATT và UMP (không quảng cáo, không theo dõi). Có xóa tài khoản, Sign in with Apple, Restore purchases.
- [ ] Thu hồi token Apple khi xóa tài khoản đăng nhập bằng Apple (cần tài khoản Apple Developer để thử).
- [x] Privacy Policy và Terms (tiếng Việt, tiếng Anh) do server AI phục vụ ở `/privacy`, `/terms`; app lấy từ cùng server với `AI_BASE_URL`. Server có môi trường staging/prod và workflow deploy ([AI-Deploy.md](AI-Deploy.md)). Còn: tài khoản Cloudflare và khoá Anthropic, điền URL, nhờ người có chuyên môn đọc lại.
- [ ] Ảnh chụp App Store. Icon và mô tả đã có (mô tả ở [AppStore-Dolingo.md](AppStore-Dolingo.md)).
- [x] Lane `beta`, `release` (fastlane, match, App Store Connect API key) và workflow TestFlight chạy tay. Còn: tài khoản Apple Developer và secrets ([TestFlight.md](TestFlight.md)).
- [ ] Đi hết checklist trong Compliance.md: còn email hỗ trợ, trang web, App Store id, tài khoản demo.
- [ ] Tag `kit/v0.1.0` và `app1/v1.0.0`.

**Xong khi:** bản Prod có trên TestFlight, checklist Compliance đã tick hết, sẵn sàng gửi review.

**Đọc:** [Compliance.md](modules/Compliance.md), [Tooling.md](modules/Tooling.md).
