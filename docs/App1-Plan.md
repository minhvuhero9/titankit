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

- [ ] TitanCore: logger, `LoadState`, lỗi chung, `AppEnvironment`, tiện ích.
- [ ] TitanNetworking: `Endpoint`, client async, interceptor (token, retry, log), theo dõi mất mạng.
- [ ] TitanStorage: UserDefaults có kiểu, Keychain, cache file, cache ảnh.
- [ ] Bản Mock cho mọi protocol.
- [ ] `AppContainer.swift` của App1 tạo các service nền.

**Xong khi:** các module có unit test chạy trên CI; App1 gọi được một API mẫu qua Networking.

**Đọc:** [Core.md](modules/Core.md), [Networking.md](modules/Networking.md), [Storage.md](modules/Storage.md).

## Giai đoạn 2: Design system

**Mục tiêu:** có base theme và component, sau đó áp token Figma của App 1.

- [ ] Định nghĩa token semantic (màu, chữ, khoảng cách, bo góc, bóng).
- [ ] Base theme sáng và tối.
- [ ] Component `TK*` cơ bản: Button, TextField, Card, List row, Toast, Loading, Sheet.
- [ ] App Catalog hiển thị mọi component với mọi theme.
- [ ] Snapshot test cho từng component.
- [ ] Xuất token Figma của App 1 vào `Tokens/`, chạy `gen-tokens`, tạo `App1Theme`.

**Xong khi:** Catalog chạy được với base theme và `App1Theme`; snapshot test xanh.

**Đọc:** [DesignSystem.md](modules/DesignSystem.md), [Tooling.md](modules/Tooling.md#sinh-token-từ-figma).

## Giai đoạn 3: Điều hướng và màn hình dựng sẵn

**Mục tiêu:** App 1 chạy được luồng Splash → Onboarding → Login → Home (Home tạm) với Mock.

- [ ] TitanNavigation: `Route`, Router, tab, sheet, deep link.
- [ ] TitanLocalization: catalog kit, đổi ngôn ngữ, formatter.
- [ ] TitanFeatures: Splash, Onboarding, Login, Settings, Profile, Delete account, WebPage, Maintenance, Force update, StateView.
- [ ] Paywall và Rate app prompt (nếu App 1 cần).
- [ ] Mỗi màn hình có trang Catalog và snapshot test.
- [ ] Nối các màn hình vào Router của App 1 bằng `Config` và callback.

**Xong khi:** đi hết luồng chính trên simulator với service Mock, ở cả `vi` và `en`, sáng và tối.

**Đọc:** [Navigation.md](modules/Navigation.md), [Features.md](modules/Features.md), [Localization.md](modules/Localization.md).

## Giai đoạn 4: Dịch vụ qua adapter Firebase

**Mục tiêu:** thay Mock bằng dịch vụ thật cho những gì App 1 cần (xem câu hỏi 4).

- [ ] Tạo project Firebase cho Dev, Staging, Prod.
- [ ] `Adapters/TitanFirebase`: Auth, Firestore/Backend, Remote Config, Analytics, Messaging.
- [ ] TitanAuth: Apple, Google, email; xóa tài khoản.
- [ ] TitanRemoteConfig: `LaunchChecker` cho bảo trì và bắt buộc cập nhật.
- [ ] TitanAnalytics: sự kiện chung của kit + sự kiện riêng App 1.
- [ ] TitanPurchase (StoreKit 2 hoặc RevenueCat), TitanAds (AdMob + UMP), TitanPush nếu cần.
- [ ] `AppContainer` chọn adapter theo môi trường.

**Xong khi:** App1-Staging đăng nhập thật, đọc Remote Config thật, sự kiện analytics hiện trên console.

**Đọc:** [Backend.md](modules/Backend.md), [Auth.md](modules/Auth.md), [RemoteConfig.md](modules/RemoteConfig.md), [Analytics.md](modules/Analytics.md), [Purchase.md](modules/Purchase.md), [Ads.md](modules/Ads.md), [Push.md](modules/Push.md).

## Giai đoạn 5: Màn hình riêng của App 1

**Mục tiêu:** làm phần nghiệp vụ riêng theo Figma của App 1.

- [ ] Liệt kê màn hình riêng từ Figma, ước lượng từng màn.
- [ ] Định nghĩa model và Repository của App 1 (ví dụ `UserRepository`).
- [ ] Viết View + ViewModel cho từng màn trong `Apps/App1/Sources/Features/`.
- [ ] Unit test ViewModel với Repository Mock.
- [ ] Xử lý loading, lỗi, rỗng, mất mạng bằng `StateView`.
- [ ] Component nào dùng lại được cho app khác thì chuyển vào kit (PR `kit/...`).

**Xong khi:** mọi màn hình trong Figma có trên App1-Staging, khớp design, test xanh.

**Đọc:** [README mục 4](README.md#4-kiến-trúc-bên-trong-một-app), [Conventions.md](Conventions.md).

## Giai đoạn 6: Compliance và TestFlight

**Mục tiêu:** bản App 1 đủ điều kiện review, có trên TestFlight.

- [ ] Hoàn thiện `PrivacyInfo.xcprivacy` và nhãn App Privacy.
- [ ] ATT, UMP, xóa tài khoản, Sign in with Apple, Restore purchases.
- [ ] Privacy Policy và Terms có URL thật.
- [ ] Icon, launch screen, ảnh chụp App Store, mô tả.
- [ ] Lane `beta` đẩy bản Staging lên TestFlight cho nhóm nội bộ.
- [ ] Đi hết checklist trong Compliance.md.
- [ ] Tag `kit/v0.1.0` và `app1/v1.0.0`.

**Xong khi:** bản Prod có trên TestFlight, checklist Compliance đã tick hết, sẵn sàng gửi review.

**Đọc:** [Compliance.md](modules/Compliance.md), [Tooling.md](modules/Tooling.md).
