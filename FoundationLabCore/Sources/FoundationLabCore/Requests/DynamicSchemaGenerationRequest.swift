import Foundation
import FoundationModels

public struct DynamicSchemaGenerationRequest: CapabilityRequest, Sendable {
    public let prompt: String
    public let schema: GenerationSchema
    public let systemPrompt: String?
    public let modelUseCase: SystemLanguageModel.UseCase
    public let guardrails: SystemLanguageModel.Guardrails?
    public let generationOptions: GenerationOptions?
    public let context: CapabilityInvocationContext

    public init(
        prompt: String,
        schema: GenerationSchema,
        systemPrompt: String? = nil,
        modelUseCase: SystemLanguageModel.UseCase = .general,
        guardrails: SystemLanguageModel.Guardrails? = nil,
        generationOptions: GenerationOptions? = nil,
        context: CapabilityInvocationContext
    ) {
        self.prompt = prompt
        self.schema = schema
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.generationOptions = generationOptions
        self.context = context
    }
}
