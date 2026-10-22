import SwiftUI
import TitanIcons
import TitanLocalization

/// Figma "Calendar" and "Date Expand": a month grid with arrows to change month.
/// Pass `progress` to draw a goal ring around each day, as on a streak or study history screen.
///
///     TKCalendar(selection: $day)
///     TKCalendar(selection: $day) { date in vm.goalProgress(on: date) }
///
/// Week start, month names and weekday names follow the `calendar` and `locale` environment values.
public struct TKCalendar: View {
    @Binding private var selection: Date?
    @State private var month: Date
    private let progress: ((Date) -> Double?)?

    @Environment(\.theme) private var theme
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - month: any day of the month shown first. nil uses the selected day, or today.
    ///   - progress: goal progress (0...1) for a day, or nil for no ring on that day.
    public init(selection: Binding<Date?>, month: Date? = nil, progress: ((Date) -> Double?)? = nil) {
        _selection = selection
        _month = State(initialValue: month ?? selection.wrappedValue ?? Date())
        self.progress = progress
    }

    public init(selection: Binding<Date>, month: Date? = nil, progress: ((Date) -> Double?)? = nil) {
        self.init(
            selection: Binding<Date?>(get: { selection.wrappedValue }, set: { if let new = $0 { selection.wrappedValue = new } }),
            month: month,
            progress: progress
        )
    }

    public var body: some View {
        let cal = localized(calendar)
        let days = TKCalendarGrid.days(in: month, calendar: cal)
        VStack(spacing: Spacing.sm) {
            TKPeriodHeader(title: Text(month.formatted(Date.FormatStyle(calendar: cal).month(.wide).year().locale(locale))),
                           titleSize: 20,
                           onPrevious: { step(-1) },
                           onNext: { step(1) })
            TKDivider()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(TKCalendarGrid.weekdaySymbols(calendar: cal).enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(theme.typography.font(size: 16, weight: .semibold, relativeTo: .callout))
                            .foregroundStyle(theme.colors.textPrimary.color)
                            .frame(maxWidth: .infinity, minHeight: 45)
                    }
                }
                ForEach(0..<(days.count / 7), id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(days[(week * 7)..<(week * 7 + 7)], id: \.date) { day in
                            TKDayCell(
                                date: day.date,
                                isInMonth: day.isInMonth,
                                isSelected: selection.map { cal.isDate($0, inSameDayAs: day.date) } ?? false,
                                progress: progress?(day.date),
                                calendar: cal
                            ) { selection = day.date }
                            .frame(maxWidth: .infinity, minHeight: 50)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(theme.colors.surfaceBackground.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(theme.colors.border.color, lineWidth: 1)
        }
    }

    private func step(_ months: Int) {
        if let next = calendar.date(byAdding: .month, value: months, to: month) {
            month = next
        }
    }

    private func localized(_ calendar: Calendar) -> Calendar {
        var cal = calendar
        cal.locale = locale
        return cal
    }
}

/// Figma "Date Collapse": one week of days with their goal rings; the selected day is boxed.
///
///     TKWeekStrip(selection: $day) { vm.goalProgress(on: $0) }
public struct TKWeekStrip: View {
    @Binding private var selection: Date
    private let progress: ((Date) -> Double?)?

    @Environment(\.theme) private var theme
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    public init(selection: Binding<Date>, progress: ((Date) -> Double?)? = nil) {
        _selection = selection
        self.progress = progress
    }

    public var body: some View {
        var cal = calendar
        cal.locale = locale
        let week = TKCalendarGrid.week(containing: selection, calendar: cal)
        let symbols = TKCalendarGrid.weekdaySymbols(calendar: cal)
        return HStack(spacing: Spacing.xxs) {
            ForEach(Array(week.enumerated()), id: \.element) { index, date in
                let isSelected = cal.isDate(date, inSameDayAs: selection)
                Button { selection = date } label: {
                    VStack(spacing: Spacing.xs) {
                        Text(symbols[index])
                            .font(theme.typography.font(size: 16, weight: .regular, relativeTo: .callout))
                            .foregroundStyle(theme.colors.textSecondary.color)
                        TKDayNumber(date: date, isInMonth: true, isHighlighted: isSelected, progress: progress?(date), calendar: cal)
                    }
                    .padding(.vertical, Spacing.xxs)
                    .frame(maxWidth: .infinity)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(theme.colors.actionPrimary.color.opacity(0.08))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .strokeBorder(theme.colors.actionPrimary.color, lineWidth: 1)
                                }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(date.formatted(Date.FormatStyle(date: .complete).locale(locale))))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

/// Figma "Date Range" header: arrows either side of a period title, e.g. "Dec 16 - Dec 22, 2024".
/// Pair it with `TKSegmentedTabs` for Weekly / Monthly / Yearly.
///
///     TKPeriodHeader(title: Text(vm.rangeTitle), onPrevious: vm.previous, onNext: vm.canGoNext ? vm.next : nil)
public struct TKPeriodHeader: View {
    private let title: Text
    private let titleSize: CGFloat
    private let onPrevious: (() -> Void)?
    private let onNext: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameters: nil for `onPrevious` or `onNext` dims that arrow and disables it.
    public init(title: Text, onPrevious: (() -> Void)?, onNext: (() -> Void)?) {
        self.init(title: title, titleSize: 18, onPrevious: onPrevious, onNext: onNext)
    }

    init(title: Text, titleSize: CGFloat, onPrevious: (() -> Void)?, onNext: (() -> Void)?) {
        self.title = title
        self.titleSize = titleSize
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            arrow(TKIcon.arrowLeft2, action: onPrevious, label: Text.kit(KitStrings.previous, locale: locale))
            title
                .font(theme.typography.font(size: titleSize, weight: titleSize >= 20 ? .bold : .semibold, relativeTo: .headline))
                .foregroundStyle(theme.colors.textPrimary.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
            arrow(TKIcon.arrowRight2, action: onNext, label: Text.kit(KitStrings.next, locale: locale))
        }
        .padding(.horizontal, Spacing.xs)
    }

    private func arrow(_ icon: TKIcon, action: (() -> Void)?, label: Text) -> some View {
        Button { action?() } label: {
            Image(tk: icon)
                .renderingMode(.template)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle((action == nil ? theme.colors.textDisabled : theme.colors.textPrimary).color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel(label)
    }
}

/// One day of the month grid.
private struct TKDayCell: View {
    let date: Date
    let isInMonth: Bool
    let isSelected: Bool
    let progress: Double?
    let calendar: Calendar
    let action: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            TKDayNumber(date: date, isInMonth: isInMonth, isHighlighted: isSelected, progress: progress,
                        calendar: calendar, fillsWhenHighlighted: progress == nil)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(date.formatted(Date.FormatStyle(date: .complete).locale(locale))))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The day number, inside a goal ring when there is progress.
private struct TKDayNumber: View {
    let date: Date
    let isInMonth: Bool
    let isHighlighted: Bool
    let progress: Double?
    let calendar: Calendar
    var fillsWhenHighlighted = false

    @Environment(\.theme) private var theme

    var body: some View {
        let number = Text(verbatim: "\(calendar.component(.day, from: date))")
            .font(theme.typography.font(size: 16, weight: .medium, relativeTo: .callout))
            .foregroundStyle(numberColor.color)
            .monospacedDigit()
        if let progress {
            TKProgressRing(progress, size: 40) { number }
                .opacity(isInMonth ? 1 : 0.5)
        } else {
            number
                .frame(width: 40, height: 40)
                .background {
                    if isHighlighted && fillsWhenHighlighted {
                        Circle().fill(theme.colors.actionPrimary.color)
                    }
                }
        }
    }

    private var numberColor: AdaptiveColor {
        if isHighlighted && fillsWhenHighlighted { return theme.colors.actionOnPrimary }
        if !isInMonth { return theme.colors.textDisabled }
        if isHighlighted || calendar.isDateInToday(date) { return theme.colors.actionPrimary }
        return theme.colors.textPrimary
    }
}

/// Date maths behind the calendar views. Kept apart from the views so it can be tested.
enum TKCalendarGrid {
    struct Day: Hashable {
        let date: Date
        let isInMonth: Bool
    }

    /// Whole weeks covering the month of `month`, starting on `calendar.firstWeekday`.
    static func days(in month: Date, calendar: Calendar) -> [Day] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let count = calendar.range(of: .day, in: .month, for: month)?.count else { return [] }
        let start = interval.start
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let total = Int((Double(leading + count) / 7).rounded(.up)) * 7
        return (0..<total).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - leading, to: start) else { return nil }
            return Day(date: date, isInMonth: (leading..<(leading + count)).contains(offset))
        }
    }

    /// The seven days of the week that contains `date`.
    static func week(containing date: Date, calendar: Calendar) -> [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// Short weekday names in display order, e.g. "Sun", "Mon" or "CN", "Th 2".
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}
