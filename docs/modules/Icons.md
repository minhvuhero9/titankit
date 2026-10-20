# TitanIcons

[← Về tổng quan](../README.md) · [DesignSystem.md](DesignSystem.md)

## 1. Một câu tóm tắt

TitanIcons là bộ 100 icon Iconly (lấy từ trang Design System của template Figma đã mua), mỗi icon có hai kiểu `light` (nét mảnh) và `bold` (đặc), dùng chung cho mọi app.

## 2. Trách nhiệm

- Giữ icon dạng vector (SVG trong asset catalog), nên nét luôn sắc ở mọi cỡ.
- Mọi icon là ảnh template: tự nhận màu chữ hiện tại, đổi theme là đổi màu icon.
- Không chứa logo thương hiệu (Google, Apple, Facebook) hay logo app. Những ảnh đó nằm trong `Assets.xcassets` của từng app.

## 3. API chính

```swift
public enum TKIcon: String, CaseIterable { case home, search, heart, show, hide, lock, message, ... }
public enum TKIconStyle { case light, bold }

Image(tk: .home)                    // kiểu light
Image(tk: .heart, style: .bold)     // kiểu bold, ví dụ tab đang chọn
TKIcon.setting.uiImage(.light)      // cho API UIKit
```

Muốn đổi màu: `.foregroundStyle(theme.colors.actionPrimary.color)`. Cỡ mặc định là 24pt; muốn cỡ khác thì thêm `.resizable().frame(width:height:)`.

Xem toàn bộ icon trong trang Catalog, mục "Icon", có nút chuyển Light / Bold.

## 4. Cách thêm icon

1. Trong Figma, icon nằm ở trang "Design System", khung "Iconography", tên dạng `Iconly/Regular/Light/<Tên>`.
2. Xuất SVG, tạo `light.<tenIcon>.imageset` và `bold.<tenIcon>.imageset` trong `Sources/TitanIcons/Resources/Icons.xcassets` (bật "Preserve Vector Data", "Render As: Template").
3. Thêm `case tenIcon` vào `TKIcon+Cases.swift`. Test `testEveryIconExistsInBothStyles` báo ngay nếu thiếu một kiểu.

Iconly đặt tên khác nhau giữa hai kiểu ở vài icon. Kit gom về một tên: `bag2`, `filter2`, `image2`, `voice2`, `dangerTriangle`, `dangerCircle`.

## 5. Bản quyền

Iconly đi kèm template đã mua, dùng được trong các app của studio. Không đưa bộ icon này lên repo công khai.

## 6. Test

- Mỗi icon có đủ hai kiểu trong asset catalog.
- Icon là ảnh template.
