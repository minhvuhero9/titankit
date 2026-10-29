import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanSpeech
import UIKit

/// Figma "roleplay chat": the conversation, then the task counter, the microphone and the hint
/// bulb. Each bubble can be heard again, translated or copied. When the partner says goodbye,
/// "Tasks Achieved!" closes the roleplay.
struct RoleplayChatScreen: View {
    let onBack: () -> Void
    private let activity: ActivityStore

    @StateObject private var viewModel: RoleplayViewModel
    @State private var speaker = PhraseSpeaker()
    @State private var showsHint = false
    @State private var showsTasks = false
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    init(
        roleplay: Roleplay,
        language: String,
        speech: any SpeechRecognizer,
        activity: ActivityStore,
        onBack: @escaping () -> Void
    ) {
        self.onBack = onBack
        self.activity = activity
        _viewModel = StateObject(wrappedValue: RoleplayViewModel(roleplay: roleplay, language: language, speech: speech,
                                                                 activity: activity))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(viewModel.messages) { message in
                            RoleplayBubble(message: message, languageCode: languageCode) {
                                activity.recordListened()
                                speaker.say(message.phrase.text, language: viewModel.language)
                            }
                            .id(message.id)
                        }
                    }
                    .padding(Spacing.lg)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    guard let last = viewModel.messages.last else { return }
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    if !last.isMine { speaker.say(last.phrase.text, language: viewModel.language) }
                }
            }
            if showsHint, let hint = viewModel.hint {
                hintCard(hint)
            }
            controls
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: Text(verbatim: viewModel.roleplay.title.localized(languageCode)), onBack: onBack)
        .tkSheet(isPresented: $showsTasks) {
            TKSheet(title: Text("roleplay.tasks \(viewModel.completedTaskCount) \(viewModel.taskCount)"),
                    primary: TKModalAction(title: Text("roleplay.tasks.close")) { showsTasks = false }) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(viewModel.roleplay.tasks) { task in
                        TaskRow(task: task, isDone: viewModel.isDone(task))
                    }
                }
            }
        }
        .tkModal(isPresented: .constant(viewModel.state == .finished)) {
            TKModal(
                title: Text(LocalizedStringKey(viewModel.completedTaskCount == viewModel.taskCount ? "roleplay.done.all" : "roleplay.done.title")),
                message: Text("roleplay.done.message"),
                primary: TKModalAction(title: Text("roleplay.done.action"), action: onBack)
            ) {
                Text(verbatim: "🏆").font(.system(size: 96))
            }
        }
        .onAppear {
            if let first = viewModel.messages.first {
                speaker.say(first.phrase.text, language: viewModel.language)
            }
        }
    }

    /// Task counter on the left, microphone in the middle, hint bulb on the right.
    private var controls: some View {
        VStack(spacing: Spacing.xs) {
            if case let .missed(score) = viewModel.state {
                Text(LocalizedStringKey(score.verdict == .notHeard ? "lesson.result.notHeard" : "roleplay.missed"))
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.feedbackError.color)
            }
            if viewModel.isMicBlocked {
                Text("roleplay.micBlocked")
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
                    .multilineTextAlignment(.center)
            }
            HStack {
                Button { showsTasks = true } label: {
                    TKProgressRing(Double(viewModel.completedTaskCount) / Double(max(1, viewModel.taskCount)), size: 52) {
                        Text(verbatim: "\(viewModel.completedTaskCount)/\(viewModel.taskCount)")
                            .tkTextStyle(.caption)
                            .foregroundStyle(theme.colors.textPrimary.color)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("roleplay.tasks \(viewModel.completedTaskCount) \(viewModel.taskCount)"))
                Spacer()
                micButton
                Spacer()
                Button { withAnimation { showsHint.toggle() } } label: {
                    Text(verbatim: "💡")
                        .font(.system(size: 26))
                        .frame(width: 52, height: 52)
                        .background(theme.colors.feedbackWarning.color.opacity(showsHint ? 0.35 : 0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("roleplay.hint"))
                .disabled(viewModel.hint == nil)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .overlay(alignment: .top) { Divider() }
    }

    private var micButton: some View {
        let listening = viewModel.state == .listening
        return Button {
            if listening {
                viewModel.stopListening()
            } else {
                speaker.stop()
                showsHint = false
                Task { await viewModel.speak() }
            }
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(tk: .voice, style: .bold)
                    .renderingMode(.template)
                    .resizable().scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(theme.colors.actionOnPrimary.color)
                    .frame(width: 72, height: 72)
                    .background(theme.gradientPrimary.linearGradient, in: Circle())
                    .overlay(Circle().stroke(theme.colors.actionPrimary.color.opacity(listening ? 0.35 : 0), lineWidth: 8).padding(-6))
                Text(LocalizedStringKey(listening ? "lesson.listening" : "lesson.tapToSpeak"))
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isMicBlocked || viewModel.state == .finished)
    }

    /// Figma "Hint": the suggested reply with its meaning; tap it to hear it, or send it when the
    /// microphone is off.
    private func hintCard(_ reply: RoleplayReply) -> some View {
        VStack(spacing: Spacing.sm) {
            Text("roleplay.hint")
                .tkTextStyle(.headline)
                .foregroundStyle(theme.colors.textPrimary.color)
            TKDivider()
            HStack(alignment: .top, spacing: Spacing.sm) {
                Button {
                    activity.recordListened()
                    speaker.say(reply.text, language: viewModel.language)
                } label: {
                    Image(tk: .volumeUp)
                        .resizable().scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(verbatim: reply.text)
                        .tkTextStyle(.headline)
                        .foregroundStyle(theme.colors.textPrimary.color)
                    Text(verbatim: reply.meaning.localized(languageCode))
                        .tkTextStyle(.caption)
                        .foregroundStyle(theme.colors.textSecondary.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if viewModel.isMicBlocked {
                TKButton("roleplay.sendHint", size: .small, shape: .pill) {
                    showsHint = false
                    viewModel.send(reply)
                }
            }
        }
        .padding(Spacing.md)
        .background(theme.colors.surfaceBackground.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.xs)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "vi"
    }
}

/// Figma roleplay bubble: the partner's in grey on the left, the learner's in the brand colour
/// on the right; the meaning shows after tapping translate; listen, translate and copy below.
private struct RoleplayBubble: View {
    let message: RoleplayViewModel.Message
    let languageCode: String
    let onListen: () -> Void

    @State private var showsMeaning = false
    @Environment(\.theme) private var theme

    var body: some View {
        let foreground = message.isMine ? theme.colors.actionOnPrimary : theme.colors.textPrimary
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: message.phrase.text)
                .tkTextStyle(.body)
                .foregroundStyle(foreground.color)
            if showsMeaning {
                Text(verbatim: message.phrase.meaning.localized(languageCode))
                    .tkTextStyle(.caption)
                    .foregroundStyle(foreground.color.opacity(0.75))
            }
            Rectangle().fill(foreground.color.opacity(0.2)).frame(height: 1)
            HStack(spacing: Spacing.sm) {
                action(Image(tk: .volumeUp), label: "roleplay.listen", tint: foreground, action: onListen)
                action(Image(systemName: "character.bubble"), label: "roleplay.translate", tint: foreground) {
                    withAnimation { showsMeaning.toggle() }
                }
                action(Image(systemName: "doc.on.doc"), label: "roleplay.copy", tint: foreground) {
                    UIPasteboard.general.string = message.phrase.text
                }
            }
        }
        .padding(Spacing.md)
        .background((message.isMine ? theme.colors.actionPrimary : theme.colors.surfaceCard).color,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: 300, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: message.isMine ? .trailing : .leading)
    }

    private func action(_ icon: Image, label: LocalizedStringKey, tint: AdaptiveColor, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .resizable().scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(tint.color)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(tint.color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }
}
