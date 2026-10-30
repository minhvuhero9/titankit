# Changelog

Ghi theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/). Kit và từng app có phiên bản riêng, gắn tag `kit/vX.Y.Z` và `app1/vX.Y.Z` ([Conventions.md](docs/Conventions.md)).

## Chưa phát hành

### Kit 0.1.0

- 15 module: Core, Networking, Storage, Icons, DesignSystem, Navigation, Localization, Auth, RemoteConfig, Purchase, Speech, Push, AI, Analytics, Features.
- Design system theo Figma Dolingo: token màu, chữ, khoảng cách; nút, ô nhập, thẻ gói, tab, toast, modal, thanh điều hướng, catalog.
- Màn dựng sẵn: splash, onboarding, khảo sát đăng ký, đăng nhập, đăng ký, quên mật khẩu, hồ sơ, xoá tài khoản (thu hồi token Apple), liên kết tài khoản, cài đặt, paywall và màn nâng cấp thành công, trang web, bảo trì và bắt buộc cập nhật.
- Adapter Firebase (`Adapters/TitanFirebase`): Auth (email, Apple, Google, khách), Analytics và Crashlytics, Remote Config.
- Mua trong app bằng StoreKit 2; gia sư AI qua server riêng (luồng SSE, token Firebase).

### Dolingo 1.0.0

- Đăng ký với 10 câu hỏi, bài học có luyện nói và chấm phát âm, roleplay có sẵn và tạo bằng AI, gia sư AI, Speak theo chủ đề, tiến độ, chuỗi ngày và huy hiệu, nhắc học hằng ngày.
- Premium: hai gói tháng và năm, `Dolingo.storekit` để mua thử trong Xcode.
- Tiếng Việt và tiếng Anh, giao diện sáng và tối.
- Compliance: privacy manifest, trang Privacy Policy và Terms trên server, xoá tài khoản trong app.
- Phát hành: lane fastlane `beta`, `release`, workflow TestFlight, ảnh App Store chụp tự động.

### Server dolingo-ai

- Cloudflare Worker gọi Claude: trò chuyện với gia sư, tạo roleplay và lượt roleplay; kiểm tra token Firebase, giới hạn lượt mỗi ngày; môi trường staging và prod, workflow deploy.
