import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "home - my courses": the learner's courses with a tick on the active one, and
/// "+ Add Course" that lists the other languages.
struct MyCoursesSheet: View {
    @ObservedObject var learning: LearningStore
    let onClose: () -> Void

    @State private var isAdding = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(learning.progress.courses, id: \.self) { language in
                    course(language, isSelected: language == learning.activeLanguage)
                }
                if isAdding {
                    ForEach(otherLanguages, id: \.self) { language in
                        course(language, isSelected: false)
                    }
                } else if !otherLanguages.isEmpty {
                    TKButton("home.addCourse", style: .outline, size: .medium, leadingIcon: Image(tk: .plus)) {
                        isAdding = true
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar("home.myCourses") {
            TKNavBarButton(Image(tk: TKSymbol.multiply), accessibilityLabel: KitStrings.string(KitStrings.Paywall.close, locale: locale),
                           action: onClose)
        }
        .presentationDetents([.medium, .large])
    }

    private var otherLanguages: [String] {
        DolingoSurvey.languages.map { $0.code }.filter { !learning.progress.courses.contains($0) }
    }

    private func course(_ language: String, isSelected: Bool) -> some View {
        TKOptionCard(title: DolingoSurvey.languageName(language), isSelected: isSelected) {
            Text(verbatim: DolingoSurvey.flag(for: language))
                .font(.system(size: 32))
                .accessibilityHidden(true)
        } action: {
            Task {
                await learning.select(language: language)
                onClose()
            }
        }
    }
}
