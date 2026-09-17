import Foundation

/// Fest eingebaute System-Prompt-Vorlagen. Bewusst kein SwiftData-`@Model`:
/// Presets sind Vorlagen, die beim Anlegen bzw. Bearbeiten eines Chats nur den
/// Textentwurf befüllen – ein Chat speichert seinen `systemPrompt` danach als
/// eigenständigen Text, unabhängig vom Preset.
enum PromptPreset: String, CaseIterable, Identifiable {
    case general
    case email

    var id: String { rawValue }

    var name: String {
        switch self {
        case .general: return "Allgemein"
        case .email: return "E-Mails schreiben"
        }
    }

    var symbolName: String {
        switch self {
        case .general: return "bubble.left.and.bubble.right"
        case .email: return "envelope"
        }
    }

    var promptText: String {
        switch self {
        case .general:
            return """
            Du bist ein hilfreicher, präziser Assistent, der lokal auf einem Mac läuft. \
            Antworte klar, freundlich und in derselben Sprache wie die letzte Nachricht \
            des Nutzers.
            """
        case .email:
            return """
            Du hilfst dabei, professionelle E-Mails zu formulieren. Achte auf einen \
            höflichen, klaren Ton, eine passende Anrede und einen passenden Gruß, sowie \
            eine sinnvolle Absatzstruktur. Frage bei fehlenden Angaben (z. B. Empfänger, \
            Anlass) kurz nach, statt Platzhalter zu erfinden. Antworte in derselben \
            Sprache wie die letzte Nachricht des Nutzers.
            """
        }
    }
}
