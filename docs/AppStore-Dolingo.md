# Thông tin App Store của Dolingo

[← Về kế hoạch App 1](App1-Plan.md)

Bản nháp để dán vào App Store Connect khi có tài khoản. Tên "Dolingo" vẫn là tên tạm theo Figma; kiểm tra trùng tên và nhãn hiệu trước khi dùng.

## Thông tin chung

| Mục | Giá trị |
| --- | --- |
| Tên | Dolingo |
| Phụ đề (vi) | Luyện nói tiếng Anh với AI |
| Subtitle (en) | Speak English with an AI tutor |
| Danh mục | Education (phụ: Reference) |
| Giá | Miễn phí, có gói Premium (tháng, năm) |
| Privacy Policy URL | `<LEGAL_BASE_URL>/privacy` |
| Terms of Use (EULA) | `<LEGAL_BASE_URL>/terms`, ghi vào cuối mô tả |
| Support URL | trang web hoặc `mailto:` của email hỗ trợ (`AppConfig.supportEmail`) |
| Từ khoá (vi) | học tiếng anh,luyện nói,phát âm,giao tiếp,từ vựng,roleplay,gia sư ai,ielts |

## Mô tả (vi)

Dolingo giúp người Việt nói tiếng Anh tự tin hơn mỗi ngày.

• Bài học ngắn: nghe câu mẫu, nói lại và xem ngay mình đúng bao nhiêu phần trăm, từng từ được tô màu.
• Roleplay: đóng vai gọi món, hỏi đường, đi phỏng vấn... và nói chuyện thật với nhân vật.
• Gia sư AI: hỏi bất cứ điều gì về tiếng Anh, được giải thích bằng tiếng Việt khi cần.
• Tự tạo roleplay: chọn vai và tình huống, AI viết kịch bản và mục tiêu cho bạn.
• Luyện nói theo chủ đề: 7 chủ đề, hơn 50 mẫu câu dùng hằng ngày.
• Theo dõi tiến độ: chuỗi ngày học, thời gian, phát âm, huy hiệu.

Dolingo Premium mở khoá mọi bài học, roleplay, chủ đề và tạo roleplay bằng AI không giới hạn. Gói tự động gia hạn qua Apple ID trừ khi tắt ít nhất 24 giờ trước khi hết kỳ; quản lý trong Cài đặt Apple ID.

Điều khoản: <LEGAL_BASE_URL>/terms · Quyền riêng tư: <LEGAL_BASE_URL>/privacy

## Nhãn App Privacy (khớp `Apps/Dolingo/Resources/PrivacyInfo.xcprivacy`)

"Do you or your third-party partners collect data?" → **Yes**. Không dùng để theo dõi (tracking).

| Loại dữ liệu | Gắn với người dùng | Mục đích |
| --- | --- | --- |
| Contact Info → Email Address | Có | App Functionality |
| Contact Info → Name | Có | App Functionality |
| Identifiers → User ID | Có | App Functionality, Analytics |
| Usage Data → Product Interaction | Có | Analytics |
| Diagnostics → Crash Data | Không | App Functionality |
| User Content → Other User Content (tin nhắn gửi AI) | Không | App Functionality |

Không thu thập: vị trí, danh bạ, ảnh, âm thanh (giọng nói được nhận dạng bằng Speech framework của Apple, không gửi về server của app), thông tin thanh toán (Apple xử lý).

## Xếp hạng tuổi

Không có nội dung bạo lực, người lớn, cờ bạc; không có trình duyệt web tự do. Có trò chuyện với AI: chọn mục nội dung do người dùng/AI tạo nếu bảng câu hỏi hỏi tới, dự kiến **12+**.

## Ghi chú cho người review

- Tài khoản demo: tạo trong Firebase Authentication (Prod) một tài khoản email riêng cho Apple, ghi email và mật khẩu vào ô Sign-in Information.
- "Đăng ký" yêu cầu trả lời 10 câu hỏi rồi tạo tài khoản; có thể đăng nhập thẳng bằng tài khoản demo ở màn đăng nhập.
- Xoá tài khoản: Tài khoản → Tài khoản & Bảo mật → Xoá tài khoản.
- Luyện nói cần quyền micro và nhận dạng giọng nói; từ chối thì bài học chuyển sang chỉ nghe và đọc.
- Gia sư AI và roleplay AI gọi server của app; mỗi tài khoản có giới hạn lượt mỗi ngày.
