import Foundation
import FoundationModels

/// Momentaufnahme des Kontext-Budgets für einen Chat: wie viele Tokens der
/// bisherige Kontext (System-Prompt bzw. Transcript) plus der aktuelle
/// Entwurfstext zusammen belegen, im Verhältnis zum Kontextfenster des Modells.
struct TokenUsage {
    let used: Int
    let limit: Int

    var fraction: Double {
        guard limit > 0 else { return 0 }
        return Double(used) / Double(limit)
    }

    var isNearLimit: Bool { fraction > 0.85 }
    var isWarning: Bool { fraction > 0.7 }

    /// Berechnet den Token-Verbrauch für `chat` + `draft`. Liefert `nil`, wenn
    /// die Zählung aus irgendeinem Grund fehlschlägt – die Anzeige ist bewusst
    /// "best effort" und darf nie selbst einen Fehlerzustand erzeugen.
    ///
    /// Folgt exakt der Verzweigung aus `ChatEngine.makeSession`: Existiert
    /// bereits ein `Transcript`, steckt der System-Prompt schon als erster
    /// Eintrag darin und darf nicht zusätzlich gezählt werden.
    @MainActor
    static func compute(chat: Chat, draft: String, kind: ModelKind) async -> TokenUsage? {
        // `tokenCount(for:)` existiert nur auf `SystemLanguageModel` (die API bietet
        // keinen eigenen Zähler für `PrivateCloudComputeLanguageModel`), daher wird
        // hier für beide Modell-Arten derselbe Tokenizer als Schätzung verwendet.
        // Die Methode selbst gibt es erst ab macOS 26.4 – auf älteren Ständen bleibt
        // die Anzeige einfach ausgeblendet.
        guard #available(macOS 26.4, *) else { return nil }
        do {
            let draftTokens = try await SystemLanguageModel.default.tokenCount(for: draft)

            let contextTokens: Int
            if let transcriptData = chat.transcriptData,
               let transcript = try? JSONDecoder().decode(Transcript.self, from: transcriptData) {
                // `Transcript` ist selbst eine `RandomAccessCollection<Entry>`.
                contextTokens = try await SystemLanguageModel.default.tokenCount(for: transcript)
            } else {
                contextTokens = try await SystemLanguageModel.default.tokenCount(for: Instructions(chat.systemPrompt))
            }

            let limit = try await Self.contextSize(for: kind)
            return TokenUsage(used: contextTokens + draftTokens, limit: limit)
        } catch {
            return nil
        }
    }

    private static func contextSize(for kind: ModelKind) async throws -> Int {
        if #available(macOS 27.0, *), kind == .privateCloudCompute {
            return try await PrivateCloudComputeLanguageModel().contextSize
        }
        return SystemLanguageModel.default.contextSize
    }
}
