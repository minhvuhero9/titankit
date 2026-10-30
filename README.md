# TitanKit

Bộ kit iOS dùng chung cho nhiều app (SwiftUI, iOS 16+, Swift 6). Mỗi app nằm trong `Apps/`, dùng các module của kit trong `Packages/TitanKit`.

- Tài liệu kiến trúc: [docs/README.md](docs/README.md)
- Bản đồ tương tác: mở [docs/index.html](docs/index.html) trong trình duyệt
- Kế hoạch App 1: [docs/App1-Plan.md](docs/App1-Plan.md)
- Danh sách màn hình Dolingo trong Figma: [docs/Dolingo-Screens.md](docs/Dolingo-Screens.md)

## Cấu trúc

```
Packages/TitanKit/   # kit: 14 module (TitanCore, TitanNetworking, TitanDesignSystem...)
Apps/Dolingo/        # App 1 (tên tạm theo template Figma)
Tuist/               # khai báo package cho Tuist
Tools/               # script dùng chung cho máy dev và CI
docs/                # tài liệu
```

## Chạy trên máy

Cần Xcode 16 và [mise](https://mise.jdx.dev) (để cài đúng phiên bản Tuist).

```bash
mise install                 # cài Tuist theo .mise.toml
cp Apps/Dolingo/Config/Secrets.example.xcconfig Apps/Dolingo/Config/Secrets.xcconfig
tuist install                # lấy package của kit
tuist generate               # sinh TitanKit.xcworkspace và mở Xcode
```

Chọn scheme `Dolingo-Dev`, `Dolingo-Staging` hoặc `Dolingo-Prod`. Ba bản có bundle id khác nhau nên cài song song được trên một máy.

Simulator không cần ký app. Chạy trên iPhone bằng Apple ID miễn phí (Personal Team):

1. Trong `Secrets.xcconfig`, bỏ dấu `//` ở hai dòng `DOLINGO_ENTITLEMENTS =` (Personal Team không ký được Sign in with Apple) và `PERSONAL_BUNDLE_SUFFIX = .yourname` (đổi `yourname`, để bundle id `com.titanstudio.dolingo.dev.<tên>` không chiếm id của tài khoản công ty sau này), rồi `tuist generate` lại.
2. Xcode → target Dolingo → Signing & Capabilities → Team: chọn Apple ID của bạn. Chạy scheme `Dolingo-Dev`.
3. Lần đầu mở app trên iPhone: Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị → tin cậy Apple ID của bạn.

Bản ký bằng Personal Team hết hạn sau 7 ngày (chạy lại từ Xcode là được). Đăng nhập Apple cần tài khoản Apple Developer. Mua gói thử được ngay khi chạy `Dolingo-Dev` từ Xcode (file `Apps/Dolingo/Dolingo.storekit`, không trừ tiền thật).

## Kiểm tra

```bash
Tools/ci-test-kit.sh          # test toàn bộ module của kit
Tools/ci-test-app.sh Dolingo  # sinh project, build và test app
```

CI chạy cả hai lệnh này trên mỗi pull request.
