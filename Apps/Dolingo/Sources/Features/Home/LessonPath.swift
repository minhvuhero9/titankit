import SwiftUI
import TitanDesignSystem
import TitanIcons

/// The lessons of one chapter as a winding path: finished lessons in green with the tutor,
/// the current one ringed in the brand colour, the rest grey with a lock, and a trophy at the end.
struct LessonPath: View {
    let lessons: [(lesson: Lesson, status: LessonStatus)]
    /// Lights the trophy up.
    let isChapterDone: Bool
    let onOpen: (Lesson) -> Void

    @Environment(\.theme) private var theme

    nonisolated static let rowHeight: CGFloat = 96
    nonisolated static let nodeSize: CGFloat = 72

    var body: some View {
        GeometryReader { proxy in
            let centers = Self.centers(count: lessons.count + 1, width: proxy.size.width)
            ZStack(alignment: .topLeading) {
                ForEach(0..<lessons.count, id: \.self) { index in
                    Path { path in
                        path.move(to: centers[index])
                        path.addLine(to: centers[index + 1])
                    }
                    .stroke(lineColor(for: index), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                }
                ForEach(lessons.indices, id: \.self) { index in
                    let lesson = lessons[index].lesson
                    LessonNode(lesson: lesson, status: lessons[index].status) { onOpen(lesson) }
                        .position(centers[index])
                }
                Text(verbatim: "🏆")
                    .font(.system(size: 48))
                    .grayscale(isChapterDone ? 0 : 1)
                    .opacity(isChapterDone ? 1 : 0.5)
                    .position(centers[lessons.count])
                    .accessibilityHidden(true)
            }
        }
        .frame(height: Self.rowHeight * CGFloat(lessons.count + 1))
    }

    private func lineColor(for index: Int) -> Color {
        let next = index + 1 < lessons.count ? lessons[index + 1].status : nil
        let lit = lessons[index].status == .done && next != .locked
        return (lit ? theme.colors.feedbackSuccess : theme.colors.border).color
    }

    /// Node centres, swinging left and right down the column like the Figma path.
    nonisolated static func centers(count: Int, width: CGFloat) -> [CGPoint] {
        let swing: [CGFloat] = [0, 0.6, 1, 0.6, 0, -0.6, -1, -0.6]
        let amplitude = max(0, width / 2 - nodeSize / 2 - 8)
        return (0..<count).map { index in
            CGPoint(x: width / 2 + swing[index % swing.count] * amplitude,
                    y: rowHeight * (CGFloat(index) + 0.5))
        }
    }
}

private struct LessonNode: View {
    let lesson: Lesson
    let status: LessonStatus
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            ZStack {
                switch status {
                case .done:
                    TKAvatar(name: lesson.tutor, size: LessonPath.nodeSize - 10)
                        .padding(5)
                        .background(theme.colors.feedbackSuccess.color, in: Circle())
                case .current:
                    TKAvatar(name: lesson.tutor, size: LessonPath.nodeSize - 10)
                        .padding(5)
                        .background(theme.colors.actionPrimary.color, in: Circle())
                        .padding(5)
                        .overlay(Circle().stroke(theme.colors.actionPrimary.color.opacity(0.3), lineWidth: 4))
                case .locked:
                    Circle()
                        .fill(theme.colors.surfaceCard.color)
                        .overlay(Circle().stroke(theme.colors.border.color, lineWidth: 5))
                        .overlay {
                            Image(tk: .lock)
                                .resizable().scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(theme.colors.textDisabled.color)
                        }
                        .frame(width: LessonPath.nodeSize, height: LessonPath.nodeSize)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(status == .locked)
        .accessibilityLabel(Text(verbatim: lesson.title.localized(locale.language.languageCode?.identifier ?? "vi")))
    }
}
