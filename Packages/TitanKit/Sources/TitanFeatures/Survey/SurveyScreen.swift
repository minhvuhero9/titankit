import SwiftUI
import TitanDesignSystem
import TitanLocalization

/// A questionnaire, one question per page, laid out like the Dolingo sign-up steps: back arrow,
/// progress bar and "3 / 12" on top, the question, the answers, and Continue pinned to the bottom.
///
///     SurveyScreen(steps: DolingoSurvey.steps, onExit: { flow.leaveSurvey() }) { answers in
///         flow.finishSurvey(answers)
///     }
public struct SurveyScreen: View {
    private let onExit: () -> Void
    private let onFinish: ([String: SurveyAnswer]) -> Void

    @StateObject private var viewModel: SurveyViewModel
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - answers: earlier answers to start from.
    ///   - onExit: back on the first step.
    ///   - onFinish: Continue on the last step, with every answer by step id.
    public init(
        steps: [SurveyStep],
        answers: [String: SurveyAnswer] = [:],
        onExit: @escaping () -> Void,
        onFinish: @escaping ([String: SurveyAnswer]) -> Void
    ) {
        self.onExit = onExit
        self.onFinish = onFinish
        _viewModel = StateObject(wrappedValue: SurveyViewModel(steps: steps, answers: answers))
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    viewModel.step.title(for: viewModel.answers)
                        .tkTextStyle(.title1)
                        .foregroundStyle(theme.colors.textPrimary.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    answers
                    viewModel.step.footnote?
                        .tkTextStyle(.caption)
                        .foregroundStyle(theme.colors.textSecondary.color)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.lg)
            }
            // A new step starts at the top.
            .id(viewModel.index)

            VStack(spacing: Spacing.sm) {
                Divider()
                TKButton(Text.kit(KitStrings.continueAction, locale: locale)) {
                    if viewModel.next() { onFinish(viewModel.answers) }
                }
                .disabled(!viewModel.canContinue)
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkButtonShape(.pill)
        .tkNavigationBar(progress: viewModel.progress, onBack: { if !viewModel.back() { onExit() } }) {
            Text(verbatim: "\(viewModel.index + 1) / \(viewModel.steps.count)")
                .tkTextStyle(.headline)
                .foregroundStyle(theme.colors.textPrimary.color)
                .monospacedDigit()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.index)
    }

    @ViewBuilder
    private var answers: some View {
        switch viewModel.step.kind {
        case let .single(options), let .multiple(options):
            VStack(spacing: Spacing.md) {
                ForEach(options) { option in
                    TKOptionCard(title: option.title, detail: option.detail, isSelected: viewModel.isSelected(option.id)) {
                        option.leading
                    } action: {
                        viewModel.select(option.id)
                    }
                }
            }
        case let .chips(options):
            TKFlowLayout {
                ForEach(options) { option in
                    TKChip(title: option.title, style: viewModel.isSelected(option.id) ? .filled : .neutral) {
                        viewModel.select(option.id)
                    }
                }
            }
        case .time:
            DatePicker(selection: timeBinding, displayedComponents: .hourAndMinute) { EmptyView() }
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
    }

    private var timeBinding: Binding<Date> {
        Binding {
            let time = viewModel.time
            return Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date()) ?? Date()
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            viewModel.setTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
        }
    }
}
