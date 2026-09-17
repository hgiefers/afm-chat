import SwiftUI
import SwiftData

@main
struct FoundationChatApp: App {
    @State private var modelCatalog = ModelCatalog()
    @State private var chatEngine = ChatEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelCatalog)
                .environment(chatEngine)
                .onAppear { modelCatalog.refresh() }
        }
        .modelContainer(for: [Chat.self, ChatMessage.self])
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Neuer Chat") {
                    NotificationCenter.default.post(name: .newChatRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let newChatRequested = Notification.Name("newChatRequested")
}
