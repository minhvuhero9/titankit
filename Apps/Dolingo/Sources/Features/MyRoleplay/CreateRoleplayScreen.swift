import SwiftUI
import TitanDesignSystem
import TitanIcons
import TitanLocalization

/// Figma "create roleplay": the emoji and title on top, then My Role, AI's Role and Scenario,
/// each with a sparkle button for the AI to fill it, the "AI Generated Goals" switch and
/// "Start Chatting". "Generating scenario..." shows while the AI completes the roleplay.
struct CreateRoleplayScreen: View {
    @StateObject private var viewModel: CreateRoleplayViewModel
    let onBack: () -> Void
    let onDone: (CustomRoleplay) -> Void

    @State private var toast: TKToast?
    @Environment(\.theme) private var theme
    @Environment(\.locale) private var locale

    private static let maxFieldLength = 200
    private static let maxScenarioLength = 1000

    init(viewModel: @autoclosure @escaping () -> CreateRoleplayViewModel,
         onBack: @escaping () -> Void,
         onDone: @escaping (CustomRoleplay) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onBack = onBack
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    TKDivider()
                    field("createRoleplay.myRole", text: $viewModel.myRole, prompt: "createRoleplay.myRole.prompt",
                          kind: .myRole)
                    field("createRoleplay.aiRole", text: $viewModel.aiRole, prompt: "createRoleplay.aiRole.prompt",
                          kind: .aiRole)
                    field("createRoleplay.scenario", text: $viewModel.scenario, prompt: "createRoleplay.scenario.prompt",
                          kind: .scenario)
                    Toggle(isOn: $viewModel.withGoals) {
                        Text("createRoleplay.goals")
                            .tkTextStyle(.headline)
                            .foregroundStyle(theme.colors.textPrimary.color)
                    }
                    .toggleStyle(.tkSwitch)
                }
                .padding(Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: Spacing.sm) {
                Divider()
                TKButton(LocalizedStringKey(viewModel.editing == nil ? "createRoleplay.start" : "createRoleplay.save"),
                         shape: .pill) {
                    Task {
                        if let roleplay = await viewModel.create() { onDone(roleplay) }
                    }
                }
                .disabled(viewModel.isBusy)
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.sm)
        }
        .background(theme.colors.surfaceBackground.color.ignoresSafeArea())
        .tkNavigationBar(LocalizedStringKey(viewModel.editing == nil ? "createRoleplay.title" : "createRoleplay.editTitle"),
                         onBack: onBack)
        .tkModal(isPresented: .constant(viewModel.isGenerating)) {
            TKModal(title: Text("createRoleplay.generating"), isLoading: true)
        }
        .tkToast($toast)
        .onChange(of: viewModel.errorKey) { key in
            guard let key else { return }
            toast = TKToast(KitStrings.string(key, locale: locale), style: .error)
            viewModel.dismissError()
        }
    }

    /// The emoji in a circle ("+" until the AI picks one) and the title under it.
    private var header: some View {
        VStack(spacing: Spacing.md) {
            Group {
                if let emoji = viewModel.emoji {
                    Text(verbatim: emoji).font(.system(size: 64))
                } else {
                    Image(tk: .plus)
                        .resizable().scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(theme.colors.textPrimary.color)
                }
            }
            .frame(width: 96, height: 96)
            .overlay(Circle().stroke(theme.colors.border.color, lineWidth: 1))
            .accessibilityHidden(true)
            TextField("createRoleplay.titlePrompt", text: limited($viewModel.title, to: Self.maxFieldLength))
                .tkTextStyle(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.colors.textPrimary.color)
                .tint(theme.colors.actionPrimary.color)
                .submitLabel(.done)
        }
        .frame(maxWidth: .infinity)
    }

    private func field(_ label: LocalizedStringKey, text: Binding<String>, prompt: LocalizedStringKey,
                       kind: CreateRoleplayViewModel.Field) -> some View {
        let isScenario = kind == .scenario
        let isFilling = viewModel.fillingField == kind
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .tkTextStyle(.label)
                .foregroundStyle(theme.colors.textPrimary.color)
            HStack(alignment: isScenario ? .bottom : .center, spacing: Spacing.sm) {
                TextField(prompt, text: limited(text, to: isScenario ? Self.maxScenarioLength : Self.maxFieldLength),
                          axis: .vertical)
                    .lineLimit(isScenario ? 4...8 : 1...2)
                    .tkTextStyle(.callout)
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .tint(theme.colors.actionPrimary.color)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Button {
                    Task { await viewModel.fill(kind) }
                } label: {
                    Group {
                        if isFilling {
                            ProgressView().tint(theme.colors.actionPrimary.color)
                        } else {
                            Image(tk: TKSymbol.sparkles)
                                .renderingMode(.template)
                                .resizable().scaledToFit()
                                .foregroundStyle(theme.colors.actionPrimary.color)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .frame(width: 36, height: 36)
                }
                .disabled(viewModel.isBusy)
                .accessibilityLabel(Text("createRoleplay.fill"))
            }
            .padding(.leading, Spacing.md)
            .padding(.trailing, Spacing.xs)
            .padding(.vertical, Spacing.sm)
            .background(theme.colors.surfaceInput.color,
                        in: RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
        }
    }

    private func limited(_ text: Binding<String>, to length: Int) -> Binding<String> {
        Binding(get: { text.wrappedValue }, set: { text.wrappedValue = String($0.prefix(length)) })
    }
}
