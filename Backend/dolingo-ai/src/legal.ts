// The Privacy Policy and Terms of Use the app and the App Store link to: GET /privacy and
// GET /terms, in Vietnamese by default or English with ?lang=en. A draft written from what the
// app does today; have it reviewed before release and update it when the app changes.

export const LEGAL_UPDATED = "2026-10-30";

export interface LegalInfo {
  /** The company that publishes the app. */
  company: string;
  /** Where users write to. */
  email: string;
}

type Lang = "vi" | "en";

interface Section {
  title: string;
  paragraphs: string[];
}

export function legalLanguage(url: URL, acceptLanguage: string | null): Lang {
  const asked = url.searchParams.get("lang");
  if (asked === "en" || asked === "vi") return asked;
  return acceptLanguage?.toLowerCase().startsWith("en") ? "en" : "vi";
}

export function privacyPage(lang: Lang, info: LegalInfo): string {
  const t = lang === "en";
  const sections: Section[] = [
    {
      title: t ? "What we collect" : "Chúng tôi thu thập gì",
      paragraphs: [
        t
          ? "Your account: email address, display name and how you sign in (email, Apple or Google), stored by Google Firebase Authentication so you can sign in on your devices."
          : "Tài khoản: email, tên hiển thị và cách bạn đăng nhập (email, Apple hoặc Google), lưu bởi Google Firebase Authentication để bạn đăng nhập được trên các thiết bị.",
        t
          ? "What you send to the AI tutor: the messages of Chat with Dolingo and of roleplays, with your English level and first name, are sent to our server and to Anthropic (Claude) to write the reply. We don't keep them after the reply; Anthropic processes them under its commercial terms and does not use them to train its models."
          : "Nội dung gửi cho gia sư AI: tin nhắn trong Trò chuyện với Dolingo và trong roleplay, kèm trình độ và tên của bạn, được gửi tới server của chúng tôi và tới Anthropic (Claude) để viết câu trả lời. Chúng tôi không lưu chúng sau khi trả lời; Anthropic xử lý theo điều khoản thương mại của họ và không dùng để huấn luyện mô hình.",
        t
          ? "Usage statistics and crash reports, through Google Analytics for Firebase and Crashlytics: screens opened, lessons finished, device model and app version. You can turn both off in Account > Data & Analytics."
          : "Thống kê sử dụng và báo cáo lỗi qua Google Analytics for Firebase và Crashlytics: màn đã mở, bài đã học xong, loại máy, phiên bản app. Bạn tắt được cả hai trong Tài khoản > Dữ liệu & Phân tích.",
      ],
    },
    {
      title: t ? "What stays on your phone" : "Những gì chỉ ở trên điện thoại",
      paragraphs: [
        t
          ? "Your learning progress, streaks, badges, saved phrases, roleplays you create and your settings are stored on your device."
          : "Tiến độ học, chuỗi ngày, huy hiệu, mẫu câu đã lưu, roleplay bạn tạo và các cài đặt được lưu trên máy của bạn.",
        t
          ? "Your voice is not recorded or sent to us. Speaking practice uses Apple's speech recognition, which runs on the device when the device supports it, and otherwise follows Apple's privacy policy."
          : "Giọng nói của bạn không được ghi lại hay gửi cho chúng tôi. Phần luyện nói dùng nhận dạng giọng nói của Apple, chạy ngay trên máy khi máy hỗ trợ, nếu không thì theo chính sách quyền riêng tư của Apple.",
      ],
    },
    {
      title: t ? "Purchases" : "Mua gói",
      paragraphs: [
        t
          ? "Premium is bought and managed through your Apple ID. We never see your payment details."
          : "Gói Premium được mua và quản lý qua Apple ID của bạn. Chúng tôi không thấy thông tin thanh toán.",
      ],
    },
    {
      title: t ? "What we don't do" : "Những điều chúng tôi không làm",
      paragraphs: [
        t
          ? "We don't sell your data, show ads or track you across other companies' apps and websites."
          : "Chúng tôi không bán dữ liệu của bạn, không hiện quảng cáo và không theo dõi bạn trên app hay website của công ty khác.",
      ],
    },
    {
      title: t ? "Your choices" : "Quyền của bạn",
      paragraphs: [
        t
          ? "Delete your account at any time in Account > Account & Security > Delete Account: your sign-in and profile are removed from Firebase. Deleting the app removes what is stored on the phone."
          : "Bạn xoá tài khoản bất cứ lúc nào trong Tài khoản > Tài khoản & Bảo mật > Xoá tài khoản: thông tin đăng nhập và hồ sơ bị xoá khỏi Firebase. Xoá app sẽ xoá những gì lưu trên máy.",
        t
          ? `To see, correct or delete other data, write to ${info.email}.`
          : `Muốn xem, sửa hay xoá dữ liệu khác, hãy viết cho ${info.email}.`,
      ],
    },
    {
      title: t ? "Children" : "Trẻ em",
      paragraphs: [
        t
          ? "Dolingo is not directed at children under 13 and we don't knowingly collect their data."
          : "Dolingo không dành cho trẻ dưới 13 tuổi và chúng tôi không cố ý thu thập dữ liệu của trẻ.",
      ],
    },
    {
      title: t ? "Changes and contact" : "Thay đổi và liên hệ",
      paragraphs: [
        t
          ? `We will update this page when the app changes how it uses data. Questions: ${info.email}.`
          : `Chúng tôi sẽ cập nhật trang này khi app thay đổi cách dùng dữ liệu. Câu hỏi: ${info.email}.`,
      ],
    },
  ];
  return page(lang, t ? "Privacy Policy" : "Chính sách quyền riêng tư", info, sections);
}

export function termsPage(lang: Lang, info: LegalInfo): string {
  const t = lang === "en";
  const sections: Section[] = [
    {
      title: t ? "Using Dolingo" : "Sử dụng Dolingo",
      paragraphs: [
        t
          ? `Dolingo is an app for learning English, published by ${info.company}. By using it you agree to these terms. You must be at least 13 years old.`
          : `Dolingo là app học tiếng Anh do ${info.company} phát hành. Khi dùng app, bạn đồng ý với các điều khoản này. Bạn cần từ 13 tuổi trở lên.`,
        t
          ? "Keep your account secure and don't use the app to harm others, break the law or overload our services."
          : "Hãy giữ an toàn tài khoản và không dùng app để gây hại cho người khác, vi phạm pháp luật hay làm quá tải dịch vụ.",
      ],
    },
    {
      title: t ? "Premium subscriptions" : "Gói Premium",
      paragraphs: [
        t
          ? "Premium is an auto-renewable subscription bought through Apple. Payment is charged to your Apple ID when you confirm. It renews automatically unless you turn it off at least 24 hours before the end of the period, in your Apple ID settings, where you also manage and cancel it. Any free trial ends when you buy a subscription."
          : "Premium là gói tự động gia hạn mua qua Apple. Tiền được trừ vào Apple ID khi bạn xác nhận. Gói tự gia hạn trừ khi bạn tắt ít nhất 24 giờ trước khi hết kỳ, trong cài đặt Apple ID, nơi bạn cũng quản lý và huỷ gói. Thời gian dùng thử (nếu có) kết thúc khi bạn mua gói.",
        t
          ? "Refunds are handled by Apple under its policies."
          : "Việc hoàn tiền do Apple xử lý theo chính sách của Apple.",
      ],
    },
    {
      title: t ? "The AI tutor" : "Gia sư AI",
      paragraphs: [
        t
          ? "Chat with Dolingo and AI roleplays are written by an AI model. Replies can be wrong or incomplete; use them for practice, not as professional advice. Daily use may be limited."
          : "Trò chuyện với Dolingo và roleplay AI do mô hình AI viết. Câu trả lời có thể sai hoặc chưa đầy đủ; hãy dùng để luyện tập, không coi là tư vấn chuyên môn. Số lượt dùng mỗi ngày có thể bị giới hạn.",
      ],
    },
    {
      title: t ? "Content" : "Nội dung",
      paragraphs: [
        t
          ? `The lessons, design and app belong to ${info.company}. You may use them for your own learning only.`
          : `Bài học, thiết kế và app thuộc về ${info.company}. Bạn chỉ dùng chúng cho việc học của mình.`,
      ],
    },
    {
      title: t ? "Liability" : "Trách nhiệm",
      paragraphs: [
        t
          ? "The app is provided as is. To the extent the law allows, we are not liable for indirect losses from using it. Nothing here limits rights you have under consumer law."
          : "App được cung cấp như hiện có. Trong phạm vi pháp luật cho phép, chúng tôi không chịu trách nhiệm cho thiệt hại gián tiếp khi dùng app. Điều khoản này không hạn chế quyền của bạn theo luật bảo vệ người tiêu dùng.",
        t
          ? "Apple's standard Licensed Application End User License Agreement also applies."
          : "Thoả thuận cấp phép người dùng cuối tiêu chuẩn của Apple (Licensed Application EULA) cũng được áp dụng.",
      ],
    },
    {
      title: t ? "Ending and changes" : "Chấm dứt và thay đổi",
      paragraphs: [
        t
          ? "You can stop using Dolingo and delete your account at any time. We may suspend accounts that break these terms. We will update this page when the terms change."
          : "Bạn có thể ngừng dùng Dolingo và xoá tài khoản bất cứ lúc nào. Chúng tôi có thể tạm khoá tài khoản vi phạm điều khoản. Chúng tôi sẽ cập nhật trang này khi điều khoản thay đổi.",
        t ? `Contact: ${info.email}.` : `Liên hệ: ${info.email}.`,
      ],
    },
  ];
  return page(lang, t ? "Terms of Use" : "Điều khoản sử dụng", info, sections);
}

function page(lang: Lang, title: string, info: LegalInfo, sections: Section[]): string {
  const updated = lang === "en" ? `Last updated: ${LEGAL_UPDATED}` : `Cập nhật: ${LEGAL_UPDATED}`;
  const body = sections
    .map((section) => `<h2>${escape(section.title)}</h2>\n${section.paragraphs.map((p) => `<p>${escape(p)}</p>`).join("\n")}`)
    .join("\n");
  return `<!doctype html>
<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)} · Dolingo</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 16px/1.6 -apple-system, system-ui, sans-serif; max-width: 680px; margin: 0 auto; padding: 24px 16px 48px; }
  h1 { font-size: 28px; margin-bottom: 4px; }
  h2 { font-size: 19px; margin-top: 28px; }
  .updated { color: #888; margin-top: 0; }
</style>
</head>
<body>
<h1>${escape(title)}</h1>
<p class="updated">${escape(updated)} · ${escape(info.company)}</p>
${body}
</body>
</html>`;
}

function escape(text: string): string {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
