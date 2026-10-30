import SwiftUI
import TitanCore
import TitanDesignSystem
import TitanIcons
import TitanNavigation
import TitanPurchase

/// Figma "home - learning language progress": the brand header with the course flag and PRO,
/// then the course as a path of lessons grouped in chapters.
struct HomeScreen: View {
    @ObservedObject var learning: LearningStore
    let purchase: any PurchaseService
    let router: Router<AppRoute>

    @State private var isPremium = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 0) {
            header
            TKAsyncContent(learning.course, retry: { Task { await learning.load() } }) { course in
                if let course {
                    path(course)
                } else {
                    TKErrorView(error: .notFound) { Task { await learning.load() } }
                }
            }
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            for await entitlements in purchase.entitlementStream {
                isPremium = entitlements.isPremium
            }
        }
    }

    private var header: some View {
        HStack {
            Text(verbatim: "🇺🇸")
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(theme.colors.actionOnPrimary.color, in: Circle())
                .accessibilityLabel(Text("home.course"))
            Spacer()
            Text(verbatim: "Dolingo")
                .tkTextStyle(.title2)
                .foregroundStyle(theme.colors.actionOnPrimary.color)
            Spacer()
            Button { router.present(.paywall) } label: {
                Text("home.pro")
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.actionPrimary.color)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(theme.colors.actionOnPrimary.color, in: Capsule())
            }
            .opacity(isPremium ? 0 : 1)
            .disabled(isPremium)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(theme.colors.actionPrimary.color.ignoresSafeArea(edges: .top))
    }

    private func path(_ course: Course) -> some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(Array(course.chapters.enumerated()), id: \.element.id) { index, chapter in
                    ChapterBanner(
                        number: index + 1,
                        title: Text(verbatim: chapter.title.localized(languageCode)),
                        color: DolingoTheme.chapterColors[index % DolingoTheme.chapterColors.count],
                        progress: learning.isUnlocked(chapter, in: course) ? learning.progress(of: chapter) : nil
                    )
                    LessonPath(
                        lessons: chapter.lessons.map { (lesson: $0, status: learning.status(of: $0, in: course)) },
                        isChapterDone: learning.progress(of: chapter) >= 1
                    ) { lesson in
                        router.present(.lesson(id: lesson.id), fullScreen: true)
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "vi"
    }
}

/// Figma "Chapter" card: a coloured banner with the chapter number and title, and a white
/// circle on the right with the progress ring, or a lock while the chapter is closed.
private struct ChapterBanner: View {
    let number: Int
    let title: Text
    let color: AdaptiveColor
    /// nil while locked.
    let progress: Double?

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("home.chapter \(number)")
                    .tkTextStyle(.headline)
                title
                    .tkTextStyle(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(theme.colors.actionOnPrimary.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                Circle().fill(theme.colors.surfaceBackground.color)
                if let progress {
                    TKProgressRing(progress, size: 52) {
                        Text(progress, format: .percent.precision(.fractionLength(0)))
                            .tkTextStyle(.caption)
                            .foregroundStyle(theme.colors.textPrimary.color)
                    }
                } else {
                    Image(tk: .lock)
                        .resizable().scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(theme.colors.textDisabled.color)
                }
            }
            .frame(width: 64, height: 64)
        }
        .padding(.leading, Spacing.md)
        .padding(.vertical, Spacing.xxs)
        .padding(.trailing, Spacing.xxs)
        .background(color.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
