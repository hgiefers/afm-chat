import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isDisabled: Bool
    let isResponding: Bool
    let onSend: () -> Void

    private var canSend: Bool {
        !isDisabled && !isResponding && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Nachricht an das Modell…")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false)
                }

                ChatInputTextView(text: $text, isDisabled: isDisabled) {
                    if canSend { onSend() }
                }
                .frame(minHeight: 22, maxHeight: 140)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: onSend) {
                if isResponding {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                }
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .help("Senden (Return)")
        }
        .padding(12)
    }
}
