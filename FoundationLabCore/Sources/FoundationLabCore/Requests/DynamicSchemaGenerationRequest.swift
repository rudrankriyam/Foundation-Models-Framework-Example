import Foundation
import FoundationModels

public struct DynamicSchemaGenerationRequest: CapabilityRequest, Sendable {
    public let prompt: String
    public let schema: GenerationSchema
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let generationOptions: FoundationLabGenerationOptions?
    public let context: CapabilityInvocationContext

    public init(
        prompt: String,
        schema: GenerationSchema,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        generationOptions: FoundationLabGenerationOptions? = nil,
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
