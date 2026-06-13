import Foundation
import FoundationModels

public enum FoundationModelsModelFactory {
    public static func makeModel(
        useCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails = .default,
        adapterURL: URL? = nil
    ) throws -> SystemLanguageModel {
        if let adapterURL {
            let adapter = try SystemLanguageModel.Adapter(fileURL: adapterURL)
            return SystemLanguageModel(adapter: adapter)
        }

        return SystemLanguageModel(
            useCase: useCase.foundationModelsValue,
            guardrails: guardrails.foundationModelsValue
        )
    }
}
