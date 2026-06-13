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
        return FoundationModelsModelFactory.availabilityResult(
            for: model,
            modelIdentifier: useCase.rawValue
        )
    }
}
