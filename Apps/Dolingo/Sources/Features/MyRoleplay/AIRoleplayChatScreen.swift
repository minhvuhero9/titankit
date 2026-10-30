import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "roleplay chat" for a roleplay the learner created: the AI partner's lines in grey with
/// translate and listen, the learner's spoken lines in the brand colour, typing dots while the AI
/// writes, then the goal counter, the microphone and the hint bulb.
struct AIRoleplayChatScreen: View {
    @StateObject private var viewModel: AIRoleplayViewModel
    private let activity: ActivityStore
    let onBack: () -> Void

    @State private var speaker = PhraseSpeaker()
    @State private var showsHint = false
    @State private var showsTasks = false
    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    init(viewModel: @autoclosure @escaping () -> AIRoleplayViewModel, activity: ActivityStore,
         onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.activity = activity
        self.onBack = onBack
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
                        if viewModel.state == .thinking {
                            ThinkingDots()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("thinking")
                        }
                        if viewModel.state == .failed {
                            TKButton("createRoleplay.retry", style: .light, size: .small, shape: .pill, fullWidth: false) {
                                Task { await viewModel.start() }
                            }
                        }
                    }
                    .padding(Spacing.lg)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    guard let last = viewModel.messages.last else { return }
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    if !last.isMine { speaker.say(last.phrase.text, language: viewModel.language) }
                }
                .onChange(of: viewModel.state) { state in
                    if state == .thinking { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
                }
            }
            if showsHint, let hint = viewModel.hint {
                hintCard(hint)
            }
            controls
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(title: Text(verbatim: "\(viewModel.roleplay.emoji) \(viewModel.roleplay.title)"), onBack: onBack)
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
        .tkToast($toast)
        .onChange(of: viewModel.errorKey) { key in
            guard let key else { return }
            toast = TKToast(KitStrings.string(key, locale: locale), style: .error)
            viewModel.dismissError()
        }
        .task { await viewModel.start() }
        .onDisappear { speaker.stop() }
    }

    /// Goal counter on the left (hidden without goals), microphone in the middle, hint bulb on the right.
    private var controls: some View {
        VStack(spacing: Spacing.xs) {
            if viewModel.state == .notHeard {
                Text("lesson.result.notHeard")
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
                .opacity(viewModel.taskCount == 0 ? 0 : 1)
                .disabled(viewModel.taskCount == 0)
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
        let canSpeak = viewModel.state == .ready || viewModel.state == .notHeard || listening
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
                    .opacity(canSpeak ? 1 : 0.5)
                Text(LocalizedStringKey(listening ? "lesson.listening" : "lesson.tapToSpeak"))
                    .tkTextStyle(.caption)
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isMicBlocked || !canSpeak)
    }

    /// The suggested reply with its meaning; tap the speaker to hear it, or send it when the
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
                    Task { await viewModel.say(reply.text) }
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

/// Three dots fading in turn while the AI writes its line.
private struct ThinkingDots: View {
    @State private var phase = 0
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(theme.colors.textSecondary.color)
                    .frame(width: 8, height: 8)
                    .opacity(phase == index ? 1 : 0.3)
            }
        }
        .padding(Spacing.md)
        .background(theme.colors.surfaceCard.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(Text("tutor.typing"))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeInOut(duration: 0.2)) { phase = (phase + 1) % 3 }
            }
        }
    }
}
