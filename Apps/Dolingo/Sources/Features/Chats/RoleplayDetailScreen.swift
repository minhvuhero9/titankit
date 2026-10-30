import SwiftUI
import TitanDesignSystem

/// Figma "roleplay - meeting new friends": the scenario, the goal and the "Also try" tasks,
/// then Start.
struct RoleplayDetailScreen: View {
    let roleplay: Roleplay
    let onBack: () -> Void
    let onStart: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(spacing: Spacing.sm) {
                        Text(verbatim: roleplay.emoji)
                            .font(.system(size: 72))
                            .accessibilityHidden(true)
                        Text(verbatim: roleplay.title.localized(languageCode))
                            .tkTextStyle(.title2)
                            .foregroundStyle(theme.colors.textPrimary.color)
                    }
                    .frame(maxWidth: .infinity)
                    TKDivider()
                    section(Text("roleplay.scenario")) {
                        Text(verbatim: roleplay.scenario.localized(languageCode))
                            .tkTextStyle(.body)
                            .foregroundStyle(theme.colors.textSecondary.color)
                    }
                    if let goal = roleplay.tasks.first {
                        section(Text("roleplay.goal")) { TaskRow(task: goal, isDone: true) }
                    }
                    if roleplay.tasks.count > 1 {
                        section(Text("roleplay.alsoTry")) {
                            ForEach(roleplay.tasks.dropFirst()) { task in
                                TaskRow(task: task, isDone: true)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            VStack(spacing: Spacing.sm) {
                Divider()
                TKButton("roleplay.start", shape: .pill, action: onStart)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: Text(verbatim: ""), onBack: onBack)
    }

    private func section<Content: View>(_ title: Text, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            title
                .tkTextStyle(.headline)
                .foregroundStyle(theme.colors.textPrimary.color)
            content()
        }
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "vi"
    }
}

/// A task card: tick, the task in the language being learned, and its meaning under it.
struct TaskRow: View {
    let task: RoleplayTask
    /// Brand tick when true, grey when the task is still to do.
    let isDone: Bool

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle((isDone ? theme.colors.actionPrimary : theme.colors.textDisabled).color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: task.text)
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(verbatim: task.meaning.localized(locale.language.languageCode?.identifier ?? "vi"))
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .tkOutlinedCard()
        .accessibilityElement(children: .combine)
    }
}
