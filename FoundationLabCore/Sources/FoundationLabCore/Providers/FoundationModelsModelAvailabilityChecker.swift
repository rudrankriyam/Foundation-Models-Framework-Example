import Foundation
import FoundationModels

public struct FoundationModelsModelAvailabilityChecker: ModelAvailabilityChecking {
    public init() {}

    public func currentAvailability() -> ModelAvailabilityResult {
        switch SystemLanguageModel.default.availability {
        case .available:
            return ModelAvailabilityResult(
                isAvailable: true,
                metadata: CapabilityExecutionMetadata(provider: "Foundation Models")
            )
        case .unavailable(let reason):
            return ModelAvailabilityResult(
                isAvailable: false,
                reason: map(reason),
                metadata: CapabilityExecutionMetadata(provider: "Foundation Models")
            )
        }
    }

    private func map(
        _ reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> ModelAvailabilityUnavailableReason {
        switch reason {
        case .deviceNotEligible:
            return .deviceNotEligible
        case .appleIntelligenceNotEnabled:
            return .appleIntelligenceNotEnabled
        case .modelNotReady:
            return .modelNotReady
        @unknown default:
            return .unknown
        }
    }
}
