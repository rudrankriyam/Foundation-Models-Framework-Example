import Foundation
import FoundationModels

public struct FoundationModelsModelAvailabilityChecker: ModelAvailabilityChecking {
    public init() {}

    public func currentAvailability() -> ModelAvailabilityResult {
        currentAvailability(useCase: .general)
    }

    public func currentAvailability(
        useCase: FoundationLabModelUseCase = .general
    ) -> ModelAvailabilityResult {
        let model = SystemLanguageModel(
            useCase: useCase.foundationModelsValue,
            guardrails: FoundationLabGuardrails.default.foundationModelsValue
        )

        switch model.availability {
        case .available:
            return ModelAvailabilityResult(
                isAvailable: true,
                metadata: CapabilityExecutionMetadata(
                    provider: "Foundation Models",
                    modelIdentifier: useCase.rawValue
                )
            )
        case .unavailable(let reason):
            return ModelAvailabilityResult(
                isAvailable: false,
                reason: map(reason),
                metadata: CapabilityExecutionMetadata(
                    provider: "Foundation Models",
                    modelIdentifier: useCase.rawValue
                )
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
