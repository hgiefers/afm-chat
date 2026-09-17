import SwiftUI

struct SidebarView: View {
    let chats: [Chat]
    @Binding var selectedChatID: UUID?
    let onDelete: (Chat) -> Void
    let onNewChat: (PromptPreset) -> Void
    let onNewCustomChat: () -> Void

    @State private var hoveredChatID: UUID?

    var body: some View {
        List(selection: $selectedChatID) {
            ForEach(chats) { chat in
                row(for: chat)
                    .tag(chat.id)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Chats")
        .overlay {
            if chats.isEmpty {
                ContentUnavailableView(
                    "Noch keine Chats",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Starte über „Neuer Chat“ oder ⌘N.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(PromptPreset.allCases) { preset in
                        Button {
                            onNewChat(preset)
                        } label: {
                            Label(preset.name, systemImage: preset.symbolName)
                        }
                    }
                    Divider()
                    Button {
                        onNewCustomChat()
                    } label: {
                        Label("Eigener Prompt…", systemImage: "square.and.pencil")
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .menuIndicator(.hidden)
                .help("Neuer Chat")
            }
        }
    }

    private func row(for chat: Chat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(chat.title)
                    .lineLimit(1)
                Text(chat.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if hoveredChatID == chat.id {
                Button {
                    onDelete(chat)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Chat löschen")
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering in
            hoveredChatID = isHovering ? chat.id : (hoveredChatID == chat.id ? nil : hoveredChatID)
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete(chat)
            } label: {
                Label("Chat löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete(chat)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}
