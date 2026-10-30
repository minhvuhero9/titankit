import SwiftUI
import TitanAI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "chat with dolingo": the tutor's messages in grey on the left, the learner's in the
/// brand colour on the right, typing dots while the reply starts, and a message field with a
/// round send button. The ⋮ menu starts a new chat.
struct TutorChatScreen: View {
    @ObservedObject var chat: TutorChat
    let onBack: () -> Void

    @State private var speaker = PhraseSpeaker()
    @State private var confirmsNewChat = false
    @State private var toast: TKToast?
    @FocusState private var isTyping: Bool
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    private static let bottomID = "bottom"

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        TutorBubble(text: KitStrings.string("tutor.greeting", locale: locale), isMine: false) {
                            speaker.say($0, language: AppConfig.learningLanguage)
                        }
                        ForEach(chat.messages) { message in
                            TutorBubble(text: message.text, isMine: message.role == .user) {
                                speaker.say($0, language: AppConfig.learningLanguage)
                            }
                        }
                        if chat.isWaitingForFirstWord {
                            TypingDots()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                        Color.clear.frame(height: 1).id(Self.bottomID)
                    }
                    .padding(Spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { proxy.scrollTo(Self.bottomID, anchor: .bottom) }
                .onChange(of: chat.messages.last?.text) { _ in
                    proxy.scrollTo(Self.bottomID, anchor: .bottom)
                }
                .onChange(of: isTyping) { _ in
                    withAnimation { proxy.scrollTo(Self.bottomID, anchor: .bottom) }
                }
            }
            composer
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar("tutor.title", onBack: onBack) {
            Menu {
                Button(role: .destructive) { confirmsNewChat = true } label: {
                    Label("tutor.newChat", systemImage: "square.and.pencil")
                }
                .disabled(chat.messages.isEmpty)
            } label: {
                Image(tk: .moreCircle)
                    .resizable().scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("tutor.more"))
        }
        .tkToast($toast)
        .confirmationDialog("tutor.newChat.title", isPresented: $confirmsNewChat, titleVisibility: .visible) {
            Button("tutor.newChat", role: .destructive) { chat.clear() }
        } message: {
            Text("tutor.newChat.message")
        }
        .onChange(of: chat.errorKey) { key in
            guard let key else { return }
            toast = TKToast(KitStrings.string(key, locale: locale), style: .error)
            chat.dismissError()
        }
        .onDisappear { speaker.stop() }
        .animation(.easeOut(duration: 0.2), value: chat.isWaitingForFirstWord)
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                TextField("tutor.placeholder", text: $chat.draft, axis: .vertical)
                    .lineLimit(1...5)
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .tint(theme.colors.actionPrimary.color)
                    .focused($isTyping)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 14)
                    .background(theme.colors.surfaceInput.color,
                                in: RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
                    .onChange(of: chat.draft) { draft in
                        if draft.count > TutorChat.maxMessageLength {
                            chat.draft = String(draft.prefix(TutorChat.maxMessageLength))
                        }
                    }
                Button {
                    chat.send()
                } label: {
                    Image(tk: .send, style: .bold)
                        .renderingMode(.template)
                        .resizable().scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(theme.colors.actionOnPrimary.color)
                        .frame(width: 52, height: 52)
                        .background((chat.canSend ? theme.colors.actionPrimary : theme.colors.textDisabled).color,
                                    in: Circle())
                }
                .disabled(!chat.canSend)
                .accessibilityLabel(Text("tutor.send"))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color)
    }
}

/// One chat message. Long press to copy, or to hear the tutor's message read aloud.
private struct TutorBubble: View {
    let text: String
    let isMine: Bool
    let onListen: (String) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Text(verbatim: text)
            .tkTextStyle(.body)
            .foregroundStyle((isMine ? theme.colors.actionOnPrimary : theme.colors.textPrimary).color)
            .textSelection(.enabled)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + 2)
            .background((isMine ? theme.colors.actionPrimary : theme.colors.surfaceCard).color,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contextMenu {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("roleplay.copy", systemImage: "doc.on.doc")
                }
                if !isMine {
                    Button {
                        onListen(text)
                    } label: {
                        Label("roleplay.listen", systemImage: "speaker.wave.2")
                    }
                }
            }
            .frame(maxWidth: 300, alignment: isMine ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

/// Three dots fading in turn while the tutor starts to answer.
private struct TypingDots: View {
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
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
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
