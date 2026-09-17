import SwiftUI

struct MessageBubbleView: View {
    let role: MessageRole
    let content: String

    private var isUser: Bool { role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            HStack(alignment: .top, spacing: 8) {
                if role == .error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

                Self.markdownText(content)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(isUser ? Color.white : Color.primary)

            if !isUser { Spacer(minLength: 48) }
        }
    }

    private var background: some ShapeStyle {
        switch role {
        case .user: return AnyShapeStyle(Color.accentColor)
        case .assistant: return AnyShapeStyle(.thickMaterial)
        case .error: return AnyShapeStyle(Color.red.opacity(0.12))
        }
    }

    private static func markdownText(_ content: String) -> Text {
        if let attributed = try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(attributed)
        }
        return Text(content)
    }
}
