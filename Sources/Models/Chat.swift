import Foundation
import SwiftData

@Model
final class Chat: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    /// Kennung des zuletzt verwendeten Modells (siehe `ModelKind`), damit ein Chat
    /// beim erneuten Öffnen mit demselben Modell fortgesetzt wird.
    var modelKindRaw: String
    /// System-Prompt dieses Chats. Kann nur wirksam geändert werden, solange noch
    /// kein `transcriptData` existiert – siehe `ChatEngine.makeSession`.
    var systemPrompt: String = PromptPreset.general.promptText
    /// Serialisiertes `Transcript` der Foundation-Models-Session, um den Gesprächs-
    /// kontext über App-Neustarts hinweg fortzusetzen (Apple's Transcript ist Codable).
    var transcriptData: Data?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.chat)
    var messages: [ChatMessage] = []

    init(
        title: String = "Neuer Chat",
        modelKindRaw: String,
        systemPrompt: String = PromptPreset.general.promptText
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.modelKindRaw = modelKindRaw
        self.systemPrompt = systemPrompt
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}
