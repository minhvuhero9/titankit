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

## Kiểm tra

```bash
Tools/ci-test-kit.sh          # test toàn bộ module của kit
Tools/ci-test-app.sh Dolingo  # sinh project, build và test app
```

CI chạy cả hai lệnh này trên mỗi pull request.
