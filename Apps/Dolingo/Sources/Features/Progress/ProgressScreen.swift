import Charts
import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "my progress": Insights (streaks, growth area, counters, study calendar, time spent)
/// and Achievements (the badge grid).
struct ProgressScreen: View {
    enum Section: Hashable {
        case insights, achievements
    }

    @ObservedObject var activity: ActivityStore
    @ObservedObject var learning: LearningStore
    let phrasebook: any PhrasebookRepository

    @State private var section = Section.insights
    @State private var phraseCount = 0
    @State private var selectedDay: Date?
    @State private var weekOffset = 0
    @State private var openBadge: Achievement?
    @Environment(\.theme) private var theme
    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(spacing: Spacing.md) {
            TKSegmentedTabs(selection: $section, options: [
                TKOption(.insights, title: "progress.insights"),
                TKOption(.achievements, title: "progress.achievements"),
            ])
            .padding(.horizontal, Spacing.lg)
            ScrollView {
                switch section {
                case .insights: insights
                case .achievements: achievements
                }
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar("tab.progress")
        .task {
            let categories = (try? await phrasebook.categories(language: AppConfig.learningLanguage)) ?? []
            phraseCount = categories.reduce(0) { $0 + $1.phrases.count }
        }
        .sheet(item: $openBadge) { badge in
            AchievementDetail(badge: badge, earnedAt: activity.earnedDate(badge))
                .presentationDetents([.medium])
        }
    }

    // MARK: - Insights

    private var insights: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                StatTile(emoji: "⚡️", value: activity.longestStreak, label: "progress.longestStreak")
                StatTile(emoji: "🔥", value: activity.currentStreak, label: "progress.currentStreak")
                StatTile(emoji: "📅", value: activity.learningDays, label: "progress.learningDays")
            }
            card(title: "progress.growth") {
                RadarChart(axes: growthAxes)
                    .frame(height: 260)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3), spacing: Spacing.sm) {
                StatTile(value: activity.stats.lessonsPassed, label: "progress.lessonsPassed")
                StatTile(value: activity.stats.perfectLessons, label: "progress.perfectLessons")
                StatTile(value: activity.stats.wordsSpoken, label: "progress.wordsSpoken")
                StatTile(value: activity.stats.sentencesSpoken, label: "progress.sentencesSpoken")
                StatTile(value: activity.stats.audioListened, label: "progress.audioListened")
                StatTile(value: activity.stats.roleplaysFinished, label: "progress.challenges")
            }
            card(title: "progress.history") {
                TKCalendar(selection: $selectedDay) { date in
                    activity.learned(on: date) ? 1 : nil
                }
            }
            card(title: "progress.timeSpent") {
                VStack(spacing: Spacing.sm) {
                    TKPeriodHeader(
                        title: Text(weekTitle),
                        onPrevious: previousWeek,
                        onNext: weekOffset < 0 ? nextWeek : nil
                    )
                    Chart(weekDays, id: \.self) { day in
                        BarMark(
                            x: .value("day", day, unit: .day),
                            y: .value("minutes", activity.minutes(on: day))
                        )
                        .foregroundStyle(theme.colors.actionPrimary.color)
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.narrow))
                        }
                    }
                    .frame(height: 180)
                    Text("progress.minutesNote")
                        .tkTextStyle(.caption)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }

    /// Five things the app can measure; the Figma chart's intonation and word stress need a
    /// pronunciation service.
    private var growthAxes: [RadarChart.Axis] {
        let course = learning.course.value.flatMap { $0 }
        let lessons = course.map { Double(learning.progress.completedLessons.count) / Double(max(1, $0.lessons.count)) } ?? 0
        let phrases = phraseCount == 0 ? 0 : Double(activity.stats.practisedPhrases.count) / Double(phraseCount)
        return [
            RadarChart.Axis(label: "progress.axis.lessons", value: lessons),
            RadarChart.Axis(label: "progress.axis.pronunciation", value: activity.pronunciation),
            RadarChart.Axis(label: "progress.axis.conversation", value: activity.roleplayTaskRate),
            RadarChart.Axis(label: "progress.axis.phrases", value: phrases),
            RadarChart.Axis(label: "progress.axis.regularity", value: activity.regularity),
        ]
    }

    private var weekDays: [Date] {
        var monday = calendar
        monday.firstWeekday = 2
        let anchor = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        guard let start = monday.dateInterval(of: .weekOfYear, for: anchor)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func previousWeek() { weekOffset -= 1 }

    private func nextWeek() { weekOffset += 1 }

    private var weekTitle: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        return "\(first.formatted(.dateTime.day().month())) - \(last.formatted(.dateTime.day().month().year()))"
    }

    // MARK: - Achievements

    private var achievements: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 3), spacing: Spacing.lg) {
            ForEach(Achievement.allCases) { badge in
                let earned = activity.earnedDate(badge) != nil
                Button { openBadge = badge } label: {
                    VStack(spacing: Spacing.xs) {
                        Text(verbatim: badge.emoji)
                            .font(.system(size: 52))
                            .grayscale(earned ? 0 : 1)
                            .opacity(earned ? 1 : 0.45)
                        Text(LocalizedStringKey("badge.\(badge.rawValue).name"))
                            .tkTextStyle(.caption)
                            .foregroundStyle((earned ? theme.colors.textPrimary : theme.colors.textDisabled).color)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
        .tkOutlinedCard()
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }

    private func card<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .tkTextStyle(.headline)
                .foregroundStyle(theme.colors.textPrimary.color)
            TKDivider()
            content()
        }
        .padding(Spacing.md)
        .tkOutlinedCard()
    }
}

/// A number with its label, optionally after an emoji, like the Figma stat cards.
private struct StatTile: View {
    var emoji: String?
    let value: Int
    let label: LocalizedStringKey

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                if let emoji { Text(verbatim: emoji).font(.system(size: 18)) }
                Text(verbatim: "\(value)")
                    .tkTextStyle(.title3)
                    .foregroundStyle(theme.colors.textPrimary.color)
            }
            Text(label)
                .tkTextStyle(.caption)
                .foregroundStyle(theme.colors.textSecondary.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .tkOutlinedCard()
        .accessibilityElement(children: .combine)
    }
}

/// Figma "Growth Area": a radar of percentages, one spoke per area, on a hexagon-style web.
struct RadarChart: View {
    struct Axis {
        let label: LocalizedStringKey
        /// From 0 to 1.
        let value: Double
    }

    let axes: [Axis]
    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = min(proxy.size.width, proxy.size.height) / 2 - 36
            ZStack {
                ForEach(1...4, id: \.self) { ring in
                    Self.polygon(values: Array(repeating: Double(ring) / 4, count: axes.count), center: center, radius: radius)
                        .stroke(theme.colors.border.color, lineWidth: 1)
                }
                Self.polygon(values: axes.map(\.value), center: center, radius: radius)
                    .fill(theme.colors.actionPrimary.color.opacity(0.35))
                Self.polygon(values: axes.map(\.value), center: center, radius: radius)
                    .stroke(theme.colors.actionPrimary.color, lineWidth: 2)
                ForEach(axes.indices, id: \.self) { index in
                    VStack(spacing: 0) {
                        Text(verbatim: "\(Int((axes[index].value * 100).rounded()))%")
                            .tkTextStyle(.headline)
                            .foregroundStyle(theme.colors.textPrimary.color)
                        Text(axes[index].label)
                            .tkTextStyle(.caption)
                            .foregroundStyle(theme.colors.textSecondary.color)
                    }
                    .position(Self.point(index: index, count: axes.count, value: 1, center: center, radius: radius + 26))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    nonisolated static func point(index: Int, count: Int, value: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = (Double(index) / Double(max(1, count))) * 2 * .pi - .pi / 2
        let length = radius * CGFloat(min(max(value, 0), 1))
        return CGPoint(x: center.x + length * CGFloat(cos(angle)), y: center.y + length * CGFloat(sin(angle)))
    }

    static func polygon(values: [Double], center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for (index, value) in values.enumerated() {
                let point = point(index: index, count: values.count, value: value, center: center, radius: radius)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}

/// Figma "my progress - achievements - badge": the badge, how it is earned, when, and Share.
private struct AchievementDetail: View {
    let badge: Achievement
    let earnedAt: Date?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(verbatim: badge.emoji)
                .font(.system(size: 96))
                .grayscale(earnedAt == nil ? 1 : 0)
            Text(LocalizedStringKey("badge.\(badge.rawValue).name"))
                .tkTextStyle(.title2)
                .foregroundStyle(theme.colors.textPrimary.color)
            Text(LocalizedStringKey("badge.\(badge.rawValue).detail"))
                .tkTextStyle(.body)
                .foregroundStyle(theme.colors.textSecondary.color)
                .multilineTextAlignment(.center)
            if let earnedAt {
                Text(earnedAt, format: .dateTime.day().month(.wide).year())
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textSecondary.color)
                ShareLink(item: String(format: KitStrings.string("badge.share %@", locale: locale), badge.emoji)) {
                    Label("progress.share", systemImage: "square.and.arrow.up")
                        .tkTextStyle(.headline)
                        .foregroundStyle(theme.colors.actionOnPrimary.color)
                        .frame(maxWidth: .infinity, minHeight: TKButton.Size.medium.height)
                        .background(theme.colors.actionPrimary.color, in: Capsule())
                }
            } else {
                Text("progress.locked")
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textDisabled.color)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
    }
}
