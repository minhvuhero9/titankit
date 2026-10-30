# Đưa Dolingo lên TestFlight

[← Về kế hoạch App 1](App1-Plan.md)

Code và lane đã sẵn; còn thiếu tài khoản Apple Developer (99 USD/năm). Khi có tài khoản, làm theo thứ tự dưới đây một lần, sau đó mỗi bản mới chỉ cần bấm chạy workflow **TestFlight** trong tab Actions.

## 1. Trên Apple Developer và App Store Connect

1. Đăng ký [Apple Developer Program](https://developer.apple.com/programs/), ghi lại **Team ID** (Membership).
2. Certificates, IDs & Profiles → Identifiers: tạo 3 App ID `com.titanstudio.dolingo`, `.staging`, `.dev`, bật **Sign in with Apple**.
3. App Store Connect → Apps → tạo app **Dolingo** (bundle `com.titanstudio.dolingo`) và **Dolingo Staging** (`com.titanstudio.dolingo.staging`). Ghi lại Apple ID của app Prod và điền vào `AppConfig.appStoreID`.
4. App Store Connect → Users and Access → Integrations → App Store Connect API: tạo khoá vai trò **App Manager**, tải file `.p8`, ghi **Key ID** và **Issuer ID**.
5. Subscriptions: tạo nhóm Premium với hai gói `com.titanstudio.dolingo.premium.monthly` và `.yearly` (trùng `AppConfig.purchase`).

## 2. Chứng chỉ ký app (fastlane match)

1. Tạo một repo GitHub **riêng tư, trống**, ví dụ `titankit-certificates`.
2. Trên máy Mac: `bundle install`, rồi
   `MATCH_GIT_URL=<repo> bundle exec fastlane match appstore --app_identifier com.titanstudio.dolingo,com.titanstudio.dolingo.staging`
   match hỏi một passphrase: đó là `MATCH_PASSWORD`, giữ kỹ.

## 3. GitHub Secrets (Settings → Secrets and variables → Actions)

| Secret | Giá trị |
| --- | --- |
| `DEVELOPMENT_TEAM` | Team ID |
| `ASC_KEY_ID`, `ASC_ISSUER_ID` | từ bước 1.4 |
| `ASC_KEY_CONTENT` | `base64 -i AuthKey_XXXX.p8` |
| `MATCH_GIT_URL`, `MATCH_PASSWORD` | từ bước 2 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `echo -n "<github user>:<token đọc repo certificates>" \| base64` |
| `DOLINGO_SECRETS_XCCONFIG` | `base64 -i Apps/Dolingo/Config/Secrets.xcconfig` (AI, Google Sign-In) |
| `DOLINGO_FIREBASE_PLIST_STAGING`, `..._PROD` | `base64 -i GoogleService-Info-Staging.plist` (và Prod) |

## 4. Gửi bản

- Actions → **TestFlight** → Run workflow → `beta`: build Staging, số build tự tăng, lên TestFlight cho nhóm nội bộ.
- `release`: build Prod lên App Store Connect; điền thông tin trong [AppStore-Dolingo.md](AppStore-Dolingo.md) rồi bấm gửi review trên web.
- Chạy trên máy Mac cũng được: `bundle exec fastlane beta app:Dolingo` với các biến môi trường như bảng trên.

## Trước khi có tài khoản

- `Dolingo.entitlements` đã có Sign in with Apple; CI build không ký (`CODE_SIGNING_ALLOWED=NO`) nên không cần tài khoản.
- Phiên bản: `MARKETING_VERSION` trong `Apps/Dolingo/Project.swift` (đang `1.0.0`); số build do fastlane đặt.
- Workflow TestFlight chạy khi chưa có secrets sẽ báo "nothing to upload" và dừng, không fail.
