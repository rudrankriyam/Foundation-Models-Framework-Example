import Foundation
import FoundationModels

public enum FoundationModelsModelFactory {
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
}
