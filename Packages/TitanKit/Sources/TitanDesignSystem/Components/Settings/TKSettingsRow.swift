import SwiftUI
import TitanIcons

/// Figma "Settings Elements": one row of a settings screen.
///
///     TKSettingsRow("Tuỳ chọn", icon: Image(tk: .setting)) { router.push(.preferences) }
///     TKSettingsRow("Ngôn ngữ", icon: Image(tk: .document), accessory: .value(Text("Tiếng Việt"))) { ... }
///     TKSettingsRow("Nhắc học hằng ngày", accessory: .toggle($remind))
///     TKSettingsRow("English", accessory: .checkmark(language == .en)) { language = .en }
///     TKSettingsRow("Đăng xuất", icon: Image(tk: .logout), role: .destructive, accessory: .none) { logOut() }
public struct TKSettingsRow: View {
    /// What sits at the end of the row.
    public enum Accessory {
        /// A chevron, for rows that open another screen.
        case chevron
        /// The current value in grey, then a chevron.
        case value(Text)
        /// A switch. Tapping the row flips it.
        case toggle(Binding<Bool>)
        /// A brand tick when true, for picking one item of a list.
        case checkmark(Bool)
        case none
    }

    public enum Role: Sendable {
        case normal
        /// Red title and icon, e.g. "Đăng xuất" or "Xoá tài khoản".
        case destructive
    }

    private let title: Text
    private let icon: Image?
    private let role: Role
    private let accessory: Accessory
    private let action: (() -> Void)?

    @Environment(\.theme) private var theme

    public init(
        _ title: LocalizedStringKey,
        icon: Image? = nil,
        role: Role = .normal,
        accessory: Accessory = .chevron,
        action: (() -> Void)? = nil
    ) {
        self.init(title: Text(title), icon: icon, role: role, accessory: accessory, action: action)
    }

    public init(
        title: Text,
        icon: Image? = nil,
        role: Role = .normal,
        accessory: Accessory = .chevron,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.role = role
        self.accessory = accessory
        self.action = action
    }

    public var body: some View {
        switch accessory {
        case .toggle(let isOn):
            Toggle(isOn: isOn) { label }
                .toggleStyle(.tkSwitch)
        default:
            Button { action?() } label: {
                HStack(spacing: Spacing.md) {
                    label
                    trailing
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(action == nil)
            .accessibilityAddTraits(isChecked ? .isSelected : [])
        }
    }

    private var isChecked: Bool {
        if case .checkmark(true) = accessory { return true }
        return false
    }

    private var label: some View {
        let tint = role == .destructive ? theme.colors.feedbackError : theme.colors.textPrimary
        return HStack(spacing: 20) {
            icon?
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            title
                .font(theme.typography.font(size: 18, weight: icon == nil ? .semibold : .bold, relativeTo: .body))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(tint.color)
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private var trailing: some View {
        switch accessory {
        case .chevron:
            chevron
        case .value(let value):
            value
                .font(theme.typography.font(size: 18, weight: .semibold, relativeTo: .body))
                .foregroundStyle(theme.colors.textSecondary.color)
            chevron
        case .checkmark(let isOn):
            Image(tk: TKSymbol.check)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(theme.colors.actionPrimary.color)
                .opacity(isOn ? 1 : 0)
                .accessibilityHidden(true)
        case .toggle, .none:
            EmptyView()
        }
    }

    private var chevron: some View {
        Image(tk: TKIcon.arrowRight2)
            .renderingMode(.template)
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundStyle((role == .destructive ? theme.colors.feedbackError : theme.colors.textPrimary).color)
            .accessibilityHidden(true)
    }
}
