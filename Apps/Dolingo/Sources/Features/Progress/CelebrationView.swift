import SwiftUI
import TitanDesignSystem
import TitanLocalization

/// Figma "streak modal" and "user earned badge modal": a full-screen congratulation with
/// Share and Continue, shown over the app after the activity that earned it.
struct CelebrationView: View {
    let celebration: Celebration
    let onContinue: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            switch celebration {
            case let .streak(days, week):
                Text(verbatim: "🔥").font(.system(size: 120))
                Text("celebration.streak.title \(days)")
                    .tkTextStyle(.title1)
                    .foregroundStyle(theme.colors.textPrimary.color)
                weekDots(week)
                TKDivider()
                Text("celebration.streak.message \(days)")
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
            case let .badge(badge):
                Text(verbatim: badge.emoji).font(.system(size: 120))
                Text(LocalizedStringKey("badge.\(badge.rawValue).name"))
                    .tkTextStyle(.title1)
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(LocalizedStringKey("badge.\(badge.rawValue).detail"))
                    .tkTextStyle(.body)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            Spacer()
            ShareLink(item: shareText) {
                Label("progress.share", systemImage: "square.and.arrow.up")
                    .tkTextStyle(.headline)
                    .foregroundStyle(theme.colors.actionOnPrimary.color)
                    .frame(maxWidth: .infinity, minHeight: TKButton.Size.large.height)
                    .background(theme.colors.actionPrimary.color, in: Capsule())
            }
            TKButton(Text.kit(KitStrings.continueAction, locale: locale), style: .light, shape: .pill, action: onContinue)
        }
        .multilineTextAlignment(.center)
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
    }

    /// Monday to Sunday with a tick on the days learned.
    private func weekDots(_ week: [Bool]) -> some View {
        var monday = calendar
        monday.firstWeekday = 2
        let names = monday.veryShortStandaloneWeekdaySymbols
        let mondayFirst = Array(names[1...]) + [names[0]]
        return HStack(spacing: Spacing.sm) {
            ForEach(week.indices, id: \.self) { index in
                VStack(spacing: Spacing.xxs) {
                    Image(systemName: week[index] ? "checkmark" : "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle((week[index] ? theme.colors.actionOnPrimary : theme.colors.textDisabled).color)
                        .frame(width: 36, height: 36)
                        .background((week[index] ? theme.colors.actionPrimary : theme.colors.border).color, in: Circle())
                    Text(verbatim: mondayFirst.indices.contains(index) ? mondayFirst[index] : "")
                        .tkTextStyle(.caption)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var shareText: String {
        switch celebration {
        case let .streak(days, _):
            String(format: KitStrings.string("celebration.streak.share %lld", locale: locale), days)
        case let .badge(badge):
            String(format: KitStrings.string("badge.share %@", locale: locale), badge.emoji)
        }
    }
}
