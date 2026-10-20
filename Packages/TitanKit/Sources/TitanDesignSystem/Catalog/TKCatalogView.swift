import SwiftUI
import TitanCore

/// Every token and component on one scrolling screen, drawn with the current theme.
/// Push it from a debug menu to check an app's theme in light and dark mode.
public struct TKCatalogView: View {
    @Environment(\.theme) private var theme
    @State private var shape = TKButton.Shape.rounded
    @State private var email = ""
    @State private var password = "secret123"
    @State private var note = ""
    @State private var toast: TKToast?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                section("Màu") { colors }
                section("Chữ") { typography }
                section("Nút") { buttons }
                section("Ô nhập") { fields }
                section("Thẻ và thông báo") { feedback }
                section("Trạng thái") { states }
            }
            .padding(Spacing.md)
        }
        .background(theme.colors.surfaceBackground.color)
        .navigationTitle("Catalog")
        .tkToast($toast)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .tkTextStyle(.title2)
                .foregroundStyle(theme.colors.textPrimary.color)
            content()
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
            TKButton("Icon", leadingIcon: Image(systemName: "cart.fill"), trailingIcon: Image(systemName: "arrow.right")) {}
            ForEach(TKButton.Size.allCases, id: \.self) { size in
                TKButton(LocalizedStringKey("\(size.rawValue) \(Int(size.height))"), size: size) {}
            }
            HStack(spacing: Spacing.sm) {
                TKIconButton(Image(systemName: "plus"), accessibilityLabel: "Thêm") {}
                TKIconButton(Image(systemName: "plus"), accessibilityLabel: "Thêm", style: .light) {}
                TKIconButton(Image(systemName: "plus"), accessibilityLabel: "Thêm", style: .neutral) {}
                TKIconButton(Image(systemName: "plus"), accessibilityLabel: "Thêm", style: .outline) {}
            }
        }
        .tkButtonShape(shape)
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            TKTextField("Email", text: $email, prompt: "Email", icon: Image(systemName: "envelope"))
            TKTextField("Mật khẩu", text: $password, icon: Image(systemName: "lock"), kind: .secure)
            TKTextField("Lỗi", text: .constant("john@doe"), icon: Image(systemName: "envelope"),
                        status: .error("Email không hợp lệ"))
            TKTextField("Hợp lệ", text: .constant("john@doe.com"), icon: Image(systemName: "envelope"),
                        status: .success("Email dùng được"))
            TKTextField("Không sửa được", text: .constant("@JohnDoe"), icon: Image(systemName: "person"))
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
