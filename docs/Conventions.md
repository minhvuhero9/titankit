# Quy ước

[← Về tổng quan](README.md)

Quy ước chung cho kit và mọi app. SwiftLint và review PR dựa trên file này.

## 1. Đặt tên

| Thứ | Quy tắc | Ví dụ |
| --- | --- | --- |
| Module của kit | Tiền tố `Titan` | `TitanCore`, `TitanAuth` |
| Component giao diện | Tiền tố `TK` | `TKButton`, `TKTextField`, `TKCard` |
| Màn hình dựng sẵn | Hậu tố `Screen` | `LoginScreen`, `PaywallScreen` |
| Cấu hình màn hình | Hậu tố `Config` | `LoginConfig` |
| Service | Hậu tố `Service`, là protocol | `AuthService` |
| Adapter | `<Nhà cung cấp><Service>Adapter` | `FirebaseAuthAdapter` |
| Mock | Tiền tố `Mock` | `MockAuthService` |
| Thư mục app | PascalCase | `Apps/App1`, `Apps/FitTracker` |
| Theme của app | `<AppName>Theme` | `App1Theme` |
| Bundle id | `com.<company>.<app>` (chữ thường) | `com.<company>.app1` |

> `<company>` chưa chốt. Bundle id Dev và Staging thêm hậu tố `.dev`, `.staging`.

### Token thiết kế

- Token semantic theo dạng `group.role.state`: `color.action.primary`, `color.action.primary.pressed`, `color.text.secondary`, `color.surface.elevated`, `color.border.error`.
- Component chỉ dùng token semantic, không dùng mã màu hay token gốc (`blue500`).
- Khoảng cách: `xs`, `sm`, `md`, `lg`, `xl` (đề xuất 4, 8, 16, 24, 32 pt). Dùng `theme.spacing.md`, không gõ số.
- Kiểu chữ theo vai trò: `display`, `title`, `headline`, `body`, `callout`, `caption`. Mọi vai trò hỗ trợ Dynamic Type.
- Chi tiết ở [DesignSystem.md](modules/DesignSystem.md).

### Chuỗi

- Key chuỗi: `<màn hình>.<thành phần>.<vai trò>`, ví dụ `login.button.submit`.
- Chuỗi của kit bắt đầu bằng `kit.`. Xem [Localization.md](modules/Localization.md).

## 2. Git

### Nhánh

| Loại việc | Tên nhánh | Ví dụ |
| --- | --- | --- |
| Sửa kit | `kit/<task>` | `kit/login-screen` |
| Việc của một app | `app/<app>/<task>` | `app/app1/home-feed` |
| Sửa gấp bản đã phát hành | `hotfix/<app>/<task>` | `hotfix/app1/crash-paywall` |

- `main` luôn build được. Không push thẳng vào `main`.
- Tên task viết thường, nối bằng gạch ngang.

### Commit

- Tiền tố theo phạm vi: `[Kit]`, `[App1]`, `[Tooling]`, `[Docs]`.
- Câu ngắn, mệnh lệnh, nói điều thay đổi: `[Kit] Add restore button to PaywallScreen`.
- Một commit một ý. Không trộn sửa kit và sửa app trong cùng commit.

### Tag

- Kit: `kit/v1.2.0`. App: `app1/v1.0.0`. Xem [Tooling.md](modules/Tooling.md#phiên-bản-kit).

## 3. Code style Swift

### Tổ chức

- Một type chính mỗi file, tên file trùng tên type. Extension nhỏ được đặt cùng file.
- Màn hình của app: `Features/<Màn hình>/<Màn hình>View.swift` và `<Màn hình>ViewModel.swift`.
- Không file nào quá 400 dòng. Tách view con khi `body` dài.

### ViewModel

```swift
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var state: LoadState<[Item]> = .idle
    private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }

    func load() async {
        state = .loading
        do { state = .loaded(try await repository.items()) }
        catch { state = .failed(error) }
    }
}
```

- Luôn `@MainActor final class ... : ObservableObject`.
- State để `private(set)`, View chỉ đọc và gửi action.
- Phụ thuộc truyền qua `init`, kiểu protocol.

### Bất đồng bộ

- Dùng `async/await`, không dùng completion handler trong code mới.
- SDK chỉ có callback thì bọc bằng `withCheckedThrowingContinuation` trong adapter.
- Gọi từ View bằng `.task { await viewModel.load() }`.
- Type đi qua ranh giới concurrency phải `Sendable` (Swift 6 strict concurrency).

### An toàn

- Không force unwrap (`!`), không `try!`, không `as!`. Dùng `guard let` và báo lỗi rõ.
- Không `fatalError` trong code chạy thật, trừ chỗ cấu hình sai rõ ràng lúc khởi động.
- Lỗi dùng enum riêng của module, ví dụ `AuthError`.

### Access control

- API của kit dành cho app: `public`. Phần còn lại: `internal` (mặc định) hoặc `private`.
- Chỉ dùng `open` khi thực sự cần cho subclass.
- Không public hóa type của SDK bên thứ ba qua API của kit.

### Khác

- Không chuỗi cứng hiển thị cho người dùng. Không mã màu, cỡ chữ, khoảng cách cứng.
- Không `print`, dùng logger của TitanCore.
- Mỗi View có `#Preview` dùng service Mock.

## 4. Quy tắc PR

- PR nhỏ, một mục đích. Tiêu đề theo tiền tố commit.
- Mô tả: làm gì, vì sao, cách test, ảnh chụp nếu đổi giao diện.
- CI xanh (SwiftLint, unit test, snapshot test) mới được merge.
- Ít nhất một người duyệt.

PR sửa kit phải thêm:

- [ ] Trang hoặc cập nhật trong **Catalog** cho component, màn hình mới hoặc đã đổi.
- [ ] **Snapshot test** cho giao diện mới hoặc đã đổi (light, dark, ít nhất 2 ngôn ngữ).
- [ ] Unit test cho logic mới, dùng Mock.
- [ ] Một dòng trong `CHANGELOG.md` mục `Unreleased`; ghi rõ nếu là breaking change.
- [ ] Cập nhật tài liệu module trong `docs/` nếu API đổi.
- [ ] Không có tên app hay logic riêng của một app trong code kit.
