import SwiftUI
import TitanCore
import TitanIcons

/// Every token and component on one scrolling screen, drawn with the current theme.
/// Push it from a debug menu to check an app's theme in light and dark mode.
public struct TKCatalogView: View {
    @Environment(\.theme) private var theme
    @State private var shape = TKButton.Shape.rounded
    @State private var email = ""
    @State private var password = "secret123"
    @State private var note = ""
    @State private var toast: TKToast?
    @State private var iconStyle = TKIconStyle.light
    @State private var remember = true
    @State private var sound = true
    @State private var vibrate = false
    @State private var level = 0
    @State private var chip = 0
    @State private var single: Int?
    @State private var multiple: Set<Int> = [1]
    @State private var tab = 0
    @State private var segment = 0
    @State private var underlineTab = 0
    @State private var query = ""
    @State private var showModal = false
    @State private var day: Date? = Date()
    @State private var weekDay = Date()
    @State private var period = 0
    @State private var reminders = true
    @State private var language = 0
    @State private var country = 0

    public init() {}

    public var body: some View {
        ScrollView {
            // Sections are type-erased and built lazily: one generic view type holding every
            // component on the page is deep enough to overflow the stack in Debug builds.
            LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                Group {
                    section("Màu") { colors }
                    section("Chữ") { typography }
                    section("Gradient") { gradients }
                }
                Group {
                    section("Icon") { icons }
                    section("Icon phụ") { iconGrid(TKSymbol.allCases, name: \.rawValue) { Image(tk: $0) } }
                    section("Icon nhiều màu") { iconGrid(TKColorIcon.allCases, name: \.rawValue) { Image(tk: $0) } }
                }
                Group {
                    section("Nút") { buttons }
                    section("Ô nhập") { fields }
                    section("Chọn") { selection }
                    section("Tag") { tags }
                    section("Điều hướng") { navigation }
                }
                Group {
                    section("Thẻ và thông báo") { feedback }
                    section("Trạng thái") { states }
                }
                Group {
                    section("Cảnh báo và hộp thoại") { alerts }
                    section("Hiển thị") { display }
                }
                Group {
                    section("Lịch và tiến độ") { dates }
                    section("Chat và danh mục") { chat }
                }
                Group {
                    section("Cài đặt") { settings }
                    section("Gói trả phí") { plans }
                }
            }
            .padding(Spacing.md)
        }
        .background(theme.colors.surfaceBackground.color)
        .navigationTitle("Catalog")
        .tkToast($toast)
        .tkModal(isPresented: $showModal, dismissOnBackgroundTap: true) {
            TKModal("Chúc mừng!", message: "Bạn đã hoàn thành bài học hôm nay.",
                     primary: TKModalAction("Tiếp tục") { showModal = false },
                     secondary: TKModalAction("Xem lại") { showModal = false }) {
                TKSuccessIllustration(.confetti)
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(title)
                    .tkTextStyle(.title2)
                    .foregroundStyle(theme.colors.textPrimary.color)
                content()
            }
        )
    }

    private var icons: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("Kiểu", selection: $iconStyle) {
                ForEach(TKIconStyle.allCases, id: \.self) { Text(verbatim: $0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            iconGrid(TKIcon.allCases, name: \.rawValue) { Image(tk: $0, style: iconStyle) }
        }
    }

    private func iconGrid<Icon: Hashable>(
        _ items: [Icon],
        name: KeyPath<Icon, String>,
        image: @escaping (Icon) -> Image
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: Spacing.sm)], spacing: Spacing.md) {
            ForEach(items, id: \.self) { icon in
                VStack(spacing: Spacing.xxs) {
                    image(icon)
                        .foregroundStyle(theme.colors.textPrimary.color)
                    Text(verbatim: icon[keyPath: name])
                        .tkTextStyle(.caption)
                        .foregroundStyle(theme.colors.textSecondary.color)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var gradients: some View {
        let g = TKPalette.Gradients.self
        let t = TKPalette.Tints.self
        let rows: [(String, TKGradient, RGBA)] = [
            ("primary", theme.gradientPrimary, t.grey),
            ("blue", g.blue, t.blue), ("purple", g.purple, t.purple), ("green", g.green, t.green),
            ("orange", g.orange, t.orange), ("red", g.red, t.red), ("teal", g.teal, t.teal),
            ("brown", g.brown, t.brown), ("yellow", g.yellow, t.yellow),
        ]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Spacing.sm)], spacing: Spacing.sm) {
            ForEach(rows, id: \.0) { row in
                let (name, gradient, tint) = row
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    RoundedRectangle(cornerRadius: theme.radius.sm)
                        .fill(gradient.linearGradient)
                        .frame(height: 44)
                    RoundedRectangle(cornerRadius: theme.radius.sm)
                        .fill(tint.color)
                        .frame(height: 20)
                    Text(verbatim: name)
                        .tkTextStyle(.caption)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
            }
        }
    }

    private var colors: some View {
        let c = theme.colors
        let swatches: [(String, AdaptiveColor)] = [
            ("actionPrimary", c.actionPrimary), ("actionPrimaryPressed", c.actionPrimaryPressed),
            ("actionSecondary", c.actionSecondary), ("actionNeutral", c.actionNeutral),
            ("actionDisabled", c.actionDisabled), ("surfaceDisabled", c.surfaceDisabled),
            ("surfaceBackground", c.surfaceBackground),
            ("surfaceCard", c.surfaceCard), ("surfaceInput", c.surfaceInput), ("border", c.border),
            ("textPrimary", c.textPrimary), ("textSecondary", c.textSecondary), ("textDisabled", c.textDisabled),
            ("feedbackSuccess", c.feedbackSuccess), ("feedbackWarning", c.feedbackWarning),
            ("feedbackError", c.feedbackError), ("feedbackInfo", c.feedbackInfo),
        ]
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: Spacing.sm)], spacing: Spacing.sm) {
            ForEach(swatches, id: \.0) { swatch in
                let (name, color) = swatch
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    RoundedRectangle(cornerRadius: theme.radius.sm)
                        .fill(color.color)
                        .frame(height: 44)
                        .overlay { RoundedRectangle(cornerRadius: theme.radius.sm).strokeBorder(c.border.color) }
                    Text(name)
                        .tkTextStyle(.caption)
                        .foregroundStyle(c.textSecondary.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ForEach(TextRole.allCases, id: \.self) { role in
                let style = theme.typography.style(role)
                Text("\(role.rawValue) \(Int(style.size))")
                    .tkTextStyle(role)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
        }
    }

    private var selection: some View {
        let options = [
            TKOption(0, title: Text(verbatim: "Mới bắt đầu")),
            TKOption(1, title: Text(verbatim: "Trung cấp")),
            TKOption(2, title: Text(verbatim: "Nâng cao")),
        ]
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Toggle(isOn: $remember) { Text(verbatim: "Checkbox") }.toggleStyle(.tkCheckbox)
            Toggle(isOn: $sound) { Text(verbatim: "Switch") }.toggleStyle(.tkSwitch)
            Toggle(isOn: $vibrate) { Text(verbatim: "Switch line") }.toggleStyle(.tkSwitch(.line))
            TKRadioGroup(selection: $level, options: options)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(options) { option in
                        TKChip(title: option.title, style: chip == option.value ? .filled : .neutral, size: .small) {
                            chip = option.value
                        }
                    }
                    TKChip(title: Text(verbatim: "Outline"), icon: Image(tk: .star), style: .outline, size: .small) {}
                }
            }
            TKDropdown(selection: $multiple, options: options)
            TKDropdown(selection: $single, options: options, prompt: "Chọn trình độ")
        }
    }

    private var navigation: some View {
        let options = [
            TKOption(0, title: Text(verbatim: "Bài học")),
            TKOption(1, title: Text(verbatim: "Từ vựng")),
            TKOption(2, title: Text(verbatim: "Ôn tập")),
        ]
        let tabs = [
            TKTabItem(0, title: Text(verbatim: "Home"), icon: .home),
            TKTabItem(1, title: Text(verbatim: "Chats"), icon: .chat),
            TKTabItem(2, title: Text(verbatim: "Speak"), icon: .voice),
            TKTabItem(3, title: Text(verbatim: "Account"), icon: .profile),
        ]
        return VStack(alignment: .leading, spacing: Spacing.md) {
            TKNavBar(title: Text(verbatim: "Navbar"), onBack: {}) {
                TKNavBarButton(Image(tk: .notification), accessibilityLabel: "Notification") {}
            }
            TKNavBar(progress: 0.6, onBack: {})
            TKSearchField(text: $query)
            TKUnderlineTabs(selection: $underlineTab, options: options)
            TKSegmentedTabs(selection: $segment, options: options)
            TKTabBar(selection: $tab, items: tabs)
        }
    }

    private var tags: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(TKTag.Style.allCases, id: \.self) { style in
                HStack(spacing: Spacing.xs) {
                    ForEach(TKTag.Tone.allCases, id: \.self) { tone in
                        TKTag(title: Text(verbatim: tone.rawValue), tone: tone, style: style, size: .small)
                    }
                }
            }
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("Dáng nút", selection: $shape) {
                Text("Bo góc").tag(TKButton.Shape.rounded)
                Text("Viên thuốc").tag(TKButton.Shape.pill)
            }
            .pickerStyle(.segmented)

            ForEach(TKButton.Style.allCases, id: \.self) { style in
                TKButton(LocalizedStringKey(style.rawValue), style: style) {}
            }
            TKButton("Disabled") {}.disabled(true)
            TKButton("Loading", isLoading: true) {}
            TKButton("Icon", leadingIcon: Image(tk: .buy, style: .bold), trailingIcon: Image(tk: .arrowRight)) {}
            ForEach(TKButton.Size.allCases, id: \.self) { size in
                TKButton(LocalizedStringKey("\(size.rawValue) \(Int(size.height))"), size: size) {}
            }
            HStack(spacing: Spacing.sm) {
                TKIconButton(Image(tk: .plus), accessibilityLabel: "Thêm") {}
                TKIconButton(Image(tk: .plus), accessibilityLabel: "Thêm", style: .light) {}
                TKIconButton(Image(tk: .plus), accessibilityLabel: "Thêm", style: .neutral) {}
                TKIconButton(Image(tk: .plus), accessibilityLabel: "Thêm", style: .outline) {}
            }
        }
        .tkButtonShape(shape)
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            TKTextField("Email", text: $email, prompt: "Email", icon: Image(tk: .message))
            TKTextField("Mật khẩu", text: $password, icon: Image(tk: .lock), kind: .secure)
            TKTextField("Lỗi", text: .constant("john@doe"), icon: Image(tk: .message),
                        status: .error("Email không hợp lệ"))
            TKTextField("Hợp lệ", text: .constant("john@doe.com"), icon: Image(tk: .message),
                        status: .success("Email dùng được"))
            TKTextField("Không sửa được", text: .constant("@JohnDoe"), icon: Image(tk: .profile))
                .disabled(true)
            TKTextField("Ghi chú", text: $note, prompt: "Viết vài dòng", kind: .multiline)
        }
    }

    private var feedback: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            TKCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("TKCard").tkTextStyle(.headline).foregroundStyle(theme.colors.textPrimary.color)
                    Text("Nền thẻ, bo góc lớn và bóng nhẹ.").tkTextStyle(.body)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
            }
            HStack(spacing: Spacing.xs) {
                ForEach(TKToast.Style.allCases, id: \.self) { style in
                    TKButton(LocalizedStringKey(style.rawValue), style: .light, size: .extraSmall) {
                        toast = TKToast("Thông báo kiểu \(style.rawValue)", style: style)
                    }
                }
            }
            Text("Skeleton đang tải")
                .tkTextStyle(.body)
                .tkSkeleton(true)
        }
    }

    private var alerts: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(TKAlert.Status.allCases, id: \.self) { status in
                TKAlert(title: Text("Cảnh báo kiểu \(status.rawValue)"), status: status)
            }
            TKButton("Mở hộp thoại", style: .light, size: .small) { showModal = true }
            HStack(spacing: Spacing.lg) {
                TKSuccessIllustration(.checkmark)
                TKSuccessIllustration(.confetti)
            }
            TKNotificationRow("Bài học mới", message: "Unit 3 đã mở khoá", time: "2 giờ trước",
                              leading: .icon(.tickSquare), isUnread: true) {}
            TKNotificationRow("Ưu đãi Premium", message: "Giảm 50% trong hôm nay", time: "Hôm qua",
                              leading: .image(Image(systemName: "gift")))
        }
    }

    private var display: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                TKAvatar(name: "Nguyễn Văn An", badge: .online)
                TKAvatar(name: "Jack", badge: .offline)
                TKAvatar(badge: .edit)
                TKAvatar(name: "Minh Vũ", size: 64, badge: .live)
            }
            .padding(.bottom, Spacing.xs)
            TKDivider()
            TKDivider("hoặc tiếp tục với")
        }
    }

    private var dates: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                ForEach([0, 0.3, 0.7, 1], id: \.self) { value in
                    TKProgressRing(value) { Text(verbatim: "\(Int(value * 100))").tkTextStyle(.caption) }
                }
                TKProgressRing(0.6, size: 64)
            }
            TKWeekStrip(selection: $weekDay) { Self.demoProgress($0) }
            TKSegmentedTabs(selection: $period, options: [
                TKOption(0, title: Text(verbatim: "Tuần")),
                TKOption(1, title: Text(verbatim: "Tháng")),
                TKOption(2, title: Text(verbatim: "Năm")),
            ])
            TKPeriodHeader(title: Text(verbatim: "16 – 22/12/2024"), onPrevious: {}, onNext: nil)
            TKCalendar(selection: $day)
            TKCalendar(selection: $day) { Self.demoProgress($0) }
        }
    }

    /// Made-up goal progress for the demo: varies by day, nothing in the future.
    nonisolated private static func demoProgress(_ date: Date) -> Double? {
        guard date <= Date() else { return 0 }
        let day = Calendar.current.component(.day, from: date)
        return Double((day * 37) % 11) / 10
    }

    private var chat: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TKMessageBubble("Chào bạn, hôm nay học gì?", time: "09:41", direction: .incoming, sender: "Anna")
            TKMessageBubble("Mình học Unit 3 nhé", time: "09:42", direction: .outgoing, status: .read)
            TKMessageBubble("Ok!", time: "09:42", direction: .incoming)
            HStack(spacing: Spacing.lg) {
                TKCategoryItem("Ngữ pháp", icon: Image(tk: TKIcon.document, style: .bold)) {}
                TKCategoryItem("Từ vựng", icon: Image(tk: TKIcon.bookmark, style: .bold)) {}
                TKCategoryItem("Nghe", icon: Image(tk: TKIcon.voice, style: .bold)) {}
            }
            .padding(.top, Spacing.md)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            TKUpgradeBanner(title: Text(verbatim: "Nâng cấp ngay!"),
                            message: Text(verbatim: "Mở khoá mọi bài học và bỏ quảng cáo")) {}
            TKListRow("Nguyễn Văn An", subtitle: "an@titanstudio.com") {
                TKAvatar(name: "Nguyễn Văn An", size: 60)
            } trailing: {
                Image(tk: TKSymbol.rotate).renderingMode(.template).foregroundStyle(theme.colors.textPrimary.color)
            }
            TKDivider()
            TKSettingsRow("Tuỳ chọn", icon: Image(tk: TKIcon.setting)) {}
            TKSettingsRow("Ngôn ngữ", icon: Image(tk: TKIcon.document), accessory: .value(Text(verbatim: "Tiếng Việt"))) {}
            TKSettingsRow("Nhắc học hằng ngày", accessory: .toggle($reminders))
            ForEach(["Tiếng Việt", "English"].indices, id: \.self) { index in
                TKSettingsRow(title: Text(verbatim: ["Tiếng Việt", "English"][index]),
                              accessory: .checkmark(language == index)) { language = index }
            }
            TKSettingsRow("Đăng xuất", icon: Image(tk: TKIcon.logout), role: .destructive, accessory: .none) {}
            ForEach(["Việt Nam", "Nhật Bản"].indices, id: \.self) { index in
                TKOptionCard(["Việt Nam", "Nhật Bản"][index], isSelected: country == index) {
                    Text(verbatim: index == 0 ? "🇻🇳" : "🇯🇵").font(.system(size: 40))
                } action: { country = index }
            }
            TKOptionCard("Google", detail: "an@gmail.com") {
                Image(tk: TKIcon.profile, style: .bold).resizable().frame(width: 48, height: 48)
            } trailing: {
                Text(verbatim: "Đã liên kết")
            } action: {}
        }
    }

    private var plans: some View {
        VStack(spacing: Spacing.lg) {
            TKPlanCard(title: Text(verbatim: "Dolingo Premium"), price: Text(verbatim: "79.000 ₫"),
                       period: Text(verbatim: "/ tháng"),
                       benefits: [Text(verbatim: "Không quảng cáo"), Text(verbatim: "Học offline"),
                                  Text(verbatim: "Trái tim vô hạn")],
                       badge: Text(verbatim: "Phổ biến nhất"), actionTitle: Text(verbatim: "Chọn gói")) {}
            TKPlanCard(title: Text(verbatim: "Dolingo Free"), price: Text(verbatim: "Miễn phí"),
                       benefits: [Text(verbatim: "5 trái tim mỗi ngày")], isCurrent: true)
        }
    }

    private var states: some View {
        VStack(spacing: Spacing.md) {
            TKLoadingView("Đang tải").frame(height: 120)
            TKEmptyState(icon: Image(systemName: "tray"), title: "Chưa có gì",
                         message: "Nội dung sẽ hiện ở đây.", actionTitle: "Tạo mới") {}
                .frame(height: 300)
            TKErrorView(error: .network(.offline)) {}
                .frame(height: 300)
        }
    }
}

#Preview {
    NavigationStack { TKCatalogView() }
}
