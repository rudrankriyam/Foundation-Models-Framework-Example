import Foundation
import FoundationModels

public enum FoundationModelsModelFactory {
    public static func currentAvailability(
        useCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails = .default,
        adapterURL: URL? = nil
    ) throws -> ModelAvailabilityResult {
        let model = try makeModel(
            useCase: useCase,
            guardrails: guardrails,
            adapterURL: adapterURL
        )
        return availabilityResult(
            for: model,
            modelIdentifier: adapterURL?.lastPathComponent ?? useCase.rawValue
        )
    }

    public static func makeModel(
        useCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails = .default,
        adapterURL: URL? = nil
    ) throws -> SystemLanguageModel {
        if let adapterURL {
            guard guardrails == .default else {
                throw FoundationLabCoreError.invalidRequest(
                    "Foundation Models adapters only support the framework's default guardrails."
                )
            }
            let adapter = try SystemLanguageModel.Adapter(fileURL: adapterURL)
            return SystemLanguageModel(adapter: adapter)
        }

        return SystemLanguageModel(
            useCase: useCase.foundationModelsValue,
            guardrails: guardrails.foundationModelsValue
        )
    }

    static func availabilityResult(
        for model: SystemLanguageModel,
        modelIdentifier: String
    ) -> ModelAvailabilityResult {
        switch model.availability {
        case .available:
            return ModelAvailabilityResult(
                isAvailable: true,
                metadata: CapabilityExecutionMetadata(
                    provider: "Foundation Models",
                    modelIdentifier: modelIdentifier
                )
            )
        case .unavailable(let reason):
            return ModelAvailabilityResult(
                isAvailable: false,
                reason: map(reason),
                metadata: CapabilityExecutionMetadata(
                    provider: "Foundation Models",
                    modelIdentifier: modelIdentifier
                )
            )
        }
    }

    private static func map(
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
