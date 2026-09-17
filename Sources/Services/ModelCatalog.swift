import Foundation
import FoundationModels
import Observation

/// Die von Apples Foundation-Models-Framework auf diesem Mac angebotenen Modelle.
/// `onDevice` existiert immer (macOS 26+); `privateCloudCompute` kommt erst mit
/// macOS 27 hinzu und wird nur aufgenommen, wenn die Laufzeitumgebung es unterstützt.
enum ModelKind: String, CaseIterable, Identifiable, Codable, Hashable {
    case onDevice
    case privateCloudCompute

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .onDevice: return "Auf dem Gerät"
        case .privateCloudCompute: return "Private Cloud Compute"
        }
    }

    var symbolName: String {
        switch self {
        case .onDevice: return "cpu"
        case .privateCloudCompute: return "cloud"
        }
    }
}

struct ModelStatus: Identifiable {
    let kind: ModelKind
    let isAvailable: Bool
    let statusText: String
    var id: String { kind.id }
}

/// Erkennt automatisch, welche Foundation-Models-Modelle auf diesem Mac verfügbar
/// sind, und liefert für jedes einen menschenlesbaren Status (z. B. wenn Apple
/// Intelligence deaktiviert ist oder das Gerät nicht unterstützt wird).
@Observable
@MainActor
final class ModelCatalog {
    private(set) var statuses: [ModelStatus] = []

    var availableKinds: [ModelKind] {
        statuses.filter(\.isAvailable).map(\.kind)
    }

    func status(for kind: ModelKind) -> ModelStatus? {
        statuses.first { $0.kind == kind }
    }

    func refresh() {
        var result: [ModelStatus] = []

        let onDevice = SystemLanguageModel.default
        result.append(
            ModelStatus(
                kind: .onDevice,
                isAvailable: onDevice.isAvailable,
                statusText: Self.describe(onDevice.availability)
            )
        )

        if #available(macOS 27.0, *) {
            let cloud = PrivateCloudComputeLanguageModel()
            result.append(
                ModelStatus(
                    kind: .privateCloudCompute,
                    isAvailable: cloud.isAvailable,
                    statusText: Self.describe(cloud.availability)
                )
            )
        }

        statuses = result
    }

    private static func describe(_ availability: SystemLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "Verfügbar"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "Dieser Mac unterstützt Apple Intelligence nicht."
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence ist in den Systemeinstellungen nicht aktiviert."
            case .modelNotReady:
                return "Das Sprachmodell wird noch vorbereitet bzw. heruntergeladen."
            @unknown default:
                return "Derzeit nicht verfügbar."
            }
        }
    }

    @available(macOS 27.0, *)
    private static func describe(_ availability: PrivateCloudComputeLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "Verfügbar"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "Dieser Mac unterstützt Private Cloud Compute nicht."
            case .systemNotReady:
                return "Private Cloud Compute ist derzeit nicht bereit."
            @unknown default:
                return "Derzeit nicht verfügbar."
            }
        }
    }
}
