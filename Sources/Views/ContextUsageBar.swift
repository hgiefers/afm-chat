import SwiftUI

struct ContextUsageBar: View {
    let usage: TokenUsage

    private var tint: Color {
        if usage.isNearLimit { return .red }
        if usage.isWarning { return .orange }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * min(usage.fraction, 1))
                }
            }
            .frame(height: 4)

            Text("\(usage.used) / \(usage.limit) Tokens")
                .font(.caption2)
                .foregroundStyle(tint == .secondary ? AnyShapeStyle(.secondary) : AnyShapeStyle(tint))
                .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .animation(.easeInOut(duration: 0.2), value: usage.used)
    }
}
