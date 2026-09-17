import SwiftUI

/// Zeigt/bearbeitet einen System-Prompt – wiederverwendet sowohl beim Anlegen
/// eines Chats mit eigenem Prompt als auch beim nachträglichen Bearbeiten eines
/// bestehenden Chats. `hasExistingContext` steuert, ob vor dem Speichern eine
/// Warnung erscheint (ein bestehender Gesprächskontext geht dabei verloren, weil
/// die Instructions eines `LanguageModelSession` nur bei dessen Erstellung
/// festgelegt werden können).
struct SystemPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @State private var showResetConfirmation = false

    let hasExistingContext: Bool
    let onSave: (String) -> Void

    init(initialText: String, hasExistingContext: Bool, onSave: @escaping (String) -> Void) {
        _draft = State(initialValue: initialText)
        self.hasExistingContext = hasExistingContext
        self.onSave = onSave
    }

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System-Prompt")
                .font(.headline)

            HStack(spacing: 8) {
                Text("Vorlage:")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ForEach(PromptPreset.allCases) { preset in
                    Button(preset.name) { draft = preset.promptText }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            TextEditor(text: $draft)
                .font(.body)
                .frame(minHeight: 160, maxHeight: 280)
                .padding(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator)
                )

            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                Button("Speichern") {
                    if hasExistingContext {
                        showResetConfirmation = true
                    } else {
                        onSave(draft)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 480)
        .alert("Kontext wird zurückgesetzt", isPresented: $showResetConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Prompt ändern & Kontext zurücksetzen", role: .destructive) {
                onSave(draft)
                dismiss()
            }
        } message: {
            Text("""
            Diese Änderung setzt den bisherigen Gesprächskontext zurück, da ein \
            Sprachmodell seine Systemanweisung nur beim Start eines neuen Kontexts \
            erhält. Der bisherige Chatverlauf bleibt sichtbar, wird dem Modell aber \
            nicht mehr mitgegeben.
            """)
        }
    }
}
