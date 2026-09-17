import SwiftUI

struct EmptyStateView: View {
    @Environment(ModelCatalog.self) private var modelCatalog
    let onNewChat: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("FoundationChat")
                .font(.title2.bold())

            Text("Unterhalte dich mit Apples Foundation Models – vollständig auf deinem Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Button(action: onNewChat) {
                Label("Neuer Chat", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderedProminent)
            .disabled(modelCatalog.availableKinds.isEmpty)

            if modelCatalog.availableKinds.isEmpty {
                ModelStatusList()
                    .frame(maxWidth: 360)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModelStatusList: View {
    @Environment(ModelCatalog.self) private var modelCatalog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(modelCatalog.statuses) { status in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: status.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(status.isAvailable ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.kind.displayName)
                            .font(.callout.weight(.medium))
                        Text(status.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }
}
