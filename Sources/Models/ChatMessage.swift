import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case error
}

@Model
final class ChatMessage: Identifiable {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var content: String
    var createdAt: Date
    var chat: Chat?

    var role: MessageRole {
        get { MessageRole(rawValue: roleRaw) ?? .assistant }
        set { roleRaw = newValue.rawValue }
    }

    init(role: MessageRole, content: String, createdAt: Date = .now) {
        self.id = UUID()
        self.roleRaw = role.rawValue
        self.content = content
        self.createdAt = createdAt
    }
}
