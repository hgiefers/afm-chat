import SwiftUI
import SwiftData

struct ChatDetailView: View {
    @Bindable var chat: Chat
    @Environment(\.modelContext) private var context
    @Environment(ModelCatalog.self) private var modelCatalog
    @Environment(ChatEngine.self) private var chatEngine
    @State private var draft = ""
    @State private var tokenUsage: TokenUsage?
    @State private var showPromptEditor = false

    private var currentKind: ModelKind { ModelKind(rawValue: chat.modelKindRaw) ?? .onDevice }
    private var currentStatus: ModelStatus? { modelCatalog.status(for: currentKind) }
    private var isModelAvailable: Bool { currentStatus?.isAvailable == true }
    private var isStreamingHere: Bool { chatEngine.isResponding && chatEngine.activeChatID == chat.id }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chat.sortedMessages) { message in
                            MessageBubbleView(role: message.role, content: message.content)
                                .id(message.id)
                        }
                        if isStreamingHere {
                            MessageBubbleView(
                                role: .assistant,
                                content: chatEngine.streamingText.isEmpty ? "…" : chatEngine.streamingText
                            )
                            .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: chat.messages.count) { scrollToBottom(proxy) }
                .onChange(of: chatEngine.streamingText) { scrollToBottom(proxy) }
                .onAppear { scrollToBottom(proxy, animated: false) }
            }

            Divider()

            if let currentStatus, !currentStatus.isAvailable {
                statusBanner(currentStatus)
            }

            if let tokenUsage {
                ContextUsageBar(usage: tokenUsage)
            }

            MessageInputView(
                text: $draft,
                isDisabled: !isModelAvailable,
                isResponding: chatEngine.isResponding,
                onSend: send
            )
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                modelPicker
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showPromptEditor = true
                } label: {
                    Image(systemName: "text.badge.gearshape")
                }
                .help("System-Prompt bearbeiten")
            }
        }
        .sheet(isPresented: $showPromptEditor) {
            SystemPromptSheet(
                initialText: chat.systemPrompt,
                hasExistingContext: !chat.messages.isEmpty,
                onSave: { newPrompt in
                    chat.systemPrompt = newPrompt
                    chat.transcriptData = nil
                    try? context.save()
                }
            )
        }
        .task(id: draft) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await recomputeTokenUsage()
        }
        .onChange(of: chat.transcriptData) {
            Task { await recomputeTokenUsage() }
        }
    }

    private func recomputeTokenUsage() async {
        tokenUsage = await TokenUsage.compute(chat: chat, draft: draft, kind: currentKind)
    }

    @ViewBuilder
    private var modelPicker: some View {
        if modelCatalog.availableKinds.count > 1 {
            Picker("Modell", selection: Binding(
                get: { currentKind },
                set: { chat.modelKindRaw = $0.rawValue }
            )) {
                ForEach(modelCatalog.availableKinds) { kind in
                    Label(kind.displayName, systemImage: kind.symbolName).tag(kind)
                }
            }
            .pickerStyle(.menu)
            .disabled(chatEngine.isResponding)
        } else {
            Label(currentKind.displayName, systemImage: currentKind.symbolName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func statusBanner(_ status: ModelStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(status.statusText)
                .font(.callout)
            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await chatEngine.send(text, to: chat, modelCatalog: modelCatalog, context: context) }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        let action = {
            if isStreamingHere {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let last = chat.sortedMessages.last?.id {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
        if animated {
            withAnimation { action() }
        } else {
            action()
        }
    }
}
