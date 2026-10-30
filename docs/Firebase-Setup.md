# Bật Firebase cho Dolingo

[← Về kế hoạch App 1](App1-Plan.md)

Code đã sẵn (`Adapters/TitanFirebase`, xem [Backend.md](modules/Backend.md)). App chỉ dùng Firebase khi file cấu hình có trong build; không có thì chạy bản Mock như trước, nên CI và người mới clone repo không cần gì thêm.

## 1. Tạo project (mỗi môi trường một project)

1. Vào [console.firebase.google.com](https://console.firebase.google.com), tạo `dolingo-dev`, `dolingo-staging`, `dolingo-prod`.
2. Trong mỗi project, thêm app iOS với bundle id:
   - Dev: `com.titanstudio.dolingo.dev`
   - Staging: `com.titanstudio.dolingo.staging`
   - Prod: `com.titanstudio.dolingo`
3. Tải `GoogleService-Info.plist` của từng app, đổi tên thành `GoogleService-Info-Dev.plist`, `-Staging.plist`, `-Prod.plist` và chép vào `Apps/Dolingo/Resources/Firebase/`. Các file này đã bị git bỏ qua (`.gitignore`), không commit.

## 2. Bật dịch vụ trong mỗi project

- **Authentication → Sign-in method:** bật Email/Password, Anonymous, Apple, Google.
  - Apple: cần App ID có capability "Sign in with Apple" trên Apple Developer (app đã có file `Dolingo.entitlements`).
  - Google: bật là xong; mở `GoogleService-Info-<Env>.plist`, chép giá trị `REVERSED_CLIENT_ID` vào `Apps/Dolingo/Config/Secrets.xcconfig` dòng `GOOGLE_REVERSED_CLIENT_ID = ...`. Mỗi môi trường một giá trị khác, nên khi đổi scheme cần đổi theo (hoặc để mỗi môi trường một file Secrets riêng).
- **Remote Config:** thêm `maintenance_enabled` (bool), `maintenance_message` (string), `minimum_version` (string). Xem [RemoteConfig.md](modules/RemoteConfig.md).
- **Analytics** và **Crashlytics:** bật trong console. Muốn Crashlytics đọc được stack trace thì thêm bước Run Script tải dSYM (chưa làm, cần khi lên TestFlight).
- **Authentication → Templates → Password reset:** sửa nội dung email đặt lại mật khẩu (tiếng Việt). Firebase gửi link chứ không gửi mã, nên với Firebase màn Quên mật khẩu dừng ở bước "Kiểm tra email".

## 3. Kiểm tra

1. `tuist install && tuist generate`, chạy scheme `Dolingo-Dev`.
2. Đăng ký bằng email: tài khoản hiện trong Authentication → Users.
3. Nút Apple và Google ở màn đăng nhập mở trang đăng nhập thật (không còn đăng nhập khách).
4. Analytics → DebugView: thêm `-FIRDebugEnabled` vào launch arguments, sẽ thấy `login_completed`, `sign_up_completed`.

## 4. Server AI

Điền Project ID vào `FIREBASE_PROJECT_ID` trong `Backend/dolingo-ai/wrangler.toml` (mỗi môi trường một Worker), tạo KV `USAGE` để giới hạn lượt mỗi ngày, rồi `npm run deploy`. Chi tiết: [AI.md](modules/AI.md#5-ai-được-gọi-server).

## Chưa làm

- Liên kết tài khoản (màn 99), đăng nhập Facebook (cần Facebook SDK và app Facebook).
- Mã OTP qua email như Figma (cần dịch vụ gửi mail riêng); hiện dùng link của Firebase.
