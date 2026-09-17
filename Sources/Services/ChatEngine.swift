import Foundation
import FoundationModels
import Observation
import SwiftData

/// Kapselt den Umgang mit `LanguageModelSession` für genau eine laufende Anfrage.
/// Es läuft bewusst immer nur eine Anfrage gleichzeitig (einfacher, robuster als
/// Nebenläufigkeit über mehrere Chats hinweg), die Eingabe wird währenddessen in
/// der UI gesperrt.
@Observable
@MainActor
final class ChatEngine {
    private(set) var isResponding = false
    private(set) var streamingText = ""
    /// Die Chat-ID, für die gerade gestreamt wird – damit nur der passende Chat
    /// die Live-Vorschau anzeigt, falls der Nutzer währenddessen die Auswahl wechselt.
    private(set) var activeChatID: UUID?

    func send(_ text: String, to chat: Chat, modelCatalog: ModelCatalog, context: ModelContext) async {
        guard !isResponding else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let kind = ModelKind(rawValue: chat.modelKindRaw) ?? .onDevice
        guard modelCatalog.status(for: kind)?.isAvailable == true else {
            appendError("Das Modell „\(kind.displayName)“ ist gerade nicht verfügbar.", to: chat, context: context)
            return
        }

        let isFirstMessage = chat.messages.isEmpty
        let userMessage = ChatMessage(role: .user, content: trimmed)
        userMessage.chat = chat
        context.insert(userMessage)
        if isFirstMessage {
            chat.title = Self.deriveTitle(from: trimmed)
        }
        chat.updatedAt = .now
        try? context.save()

        isResponding = true
        activeChatID = chat.id
        streamingText = ""
        defer {
            isResponding = false
            activeChatID = nil
            streamingText = ""
        }

        do {
            let session = Self.makeSession(kind: kind, transcriptData: chat.transcriptData, instructions: chat.systemPrompt)
            let stream = session.streamResponse(to: trimmed)
            for try await snapshot in stream {
                streamingText = snapshot.content
            }

            let assistantMessage = ChatMessage(role: .assistant, content: streamingText)
            assistantMessage.chat = chat
            context.insert(assistantMessage)
            chat.transcriptData = try? JSONEncoder().encode(session.transcript)
            chat.updatedAt = .now
            try? context.save()
        } catch {
            let message = Self.contextOverflowMessage(for: error) ?? error.localizedDescription
            appendError(message, to: chat, context: context)
        }
    }

    /// Liefert eine präzisere, deutschsprachige Meldung, wenn der Fehler auf ein
    /// überschrittenes Kontextfenster zurückgeht. Auf macOS 27+ liefert die API
    /// exakte Token-Zahlen, auf macOS 26 nur eine Debug-Beschreibung.
    private static func contextOverflowMessage(for error: Error) -> String? {
        if #available(macOS 27.0, *),
           let lmError = error as? LanguageModelError,
           case .contextSizeExceeded(let details) = lmError {
            return "Kontext-Limit überschritten (\(details.tokenCount)/\(details.contextSize) Tokens). Starte einen neuen Chat oder kürze deine Nachricht."
        }
        if let genError = error as? LanguageModelSession.GenerationError,
           case .exceededContextWindowSize(let ctx) = genError {
            return "Kontext-Limit überschritten: \(ctx.debugDescription). Starte einen neuen Chat oder kürze deine Nachricht."
        }
        return nil
    }

    private func appendError(_ message: String, to chat: Chat, context: ModelContext) {
        let errorMessage = ChatMessage(role: .error, content: message)
        errorMessage.chat = chat
        context.insert(errorMessage)
        chat.updatedAt = .now
        try? context.save()
    }

    private static func makeSession(kind: ModelKind, transcriptData: Data?, instructions: String) -> LanguageModelSession {
        let transcript = transcriptData.flatMap { try? JSONDecoder().decode(Transcript.self, from: $0) }

        if #available(macOS 27.0, *), kind == .privateCloudCompute {
            let model = PrivateCloudComputeLanguageModel()
            if let transcript {
                return LanguageModelSession(model: model, transcript: transcript)
            }
            return LanguageModelSession(model: model, instructions: instructions)
        }

        let model = SystemLanguageModel.default
        if let transcript {
            return LanguageModelSession(model: model, transcript: transcript)
        }
        return LanguageModelSession(model: model, instructions: instructions)
    }

    private static func deriveTitle(from text: String) -> String {
        let maxLength = 40
        if text.count <= maxLength { return text }
        return String(text.prefix(maxLength)) + "…"
    }
}
