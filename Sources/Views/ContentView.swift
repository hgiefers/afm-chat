import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(ModelCatalog.self) private var modelCatalog
    @Query(sort: \Chat.updatedAt, order: .reverse) private var chats: [Chat]

    @State private var selectedChatID: UUID?
    @State private var showCustomPromptSheet = false

    private var selectedChat: Chat? {
        chats.first { $0.id == selectedChatID }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                chats: chats,
                selectedChatID: $selectedChatID,
                onDelete: delete,
                onNewChat: { createChat(preset: $0) },
                onNewCustomChat: { showCustomPromptSheet = true }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            if let selectedChat {
                ChatDetailView(chat: selectedChat)
                    .id(selectedChat.id)
            } else {
                EmptyStateView(onNewChat: { createChat() })
            }
        }
        .onAppear {
            if selectedChatID == nil {
                selectedChatID = chats.first?.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newChatRequested)) { _ in
            createChat()
        }
        .sheet(isPresented: $showCustomPromptSheet) {
            SystemPromptSheet(
                initialText: PromptPreset.general.promptText,
                hasExistingContext: false,
                onSave: { createChat(customPrompt: $0) }
            )
        }
    }

    private func createChat(preset: PromptPreset = .general) {
        createChat(customPrompt: preset.promptText)
    }

    private func createChat(customPrompt: String) {
        let kind = modelCatalog.availableKinds.first ?? .onDevice
        let chat = Chat(modelKindRaw: kind.rawValue, systemPrompt: customPrompt)
        context.insert(chat)
        try? context.save()
        selectedChatID = chat.id
    }

    private func delete(_ chat: Chat) {
        if selectedChatID == chat.id {
            selectedChatID = chats.first { $0.id != chat.id }?.id
        }
        context.delete(chat)
        try? context.save()
    }
}
