import Foundation
import FoundationModels

public struct StructuredGenerationRequest<Output: Generable & Sendable>: CapabilityRequest, Sendable {
    public let prompt: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationLabModelUseCase
    public let guardrails: FoundationLabGuardrails?
    public let adapterURL: URL?
    public let generationOptions: FoundationLabGenerationOptions?
    public let includeSchemaInPrompt: Bool
    public let context: CapabilityInvocationContext

    public init(
        prompt: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationLabModelUseCase = .general,
        guardrails: FoundationLabGuardrails? = nil,
        adapterURL: URL? = nil,
        generationOptions: FoundationLabGenerationOptions? = nil,
        includeSchemaInPrompt: Bool = true,
        context: CapabilityInvocationContext
    ) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.adapterURL = adapterURL
        self.generationOptions = generationOptions
        self.includeSchemaInPrompt = includeSchemaInPrompt
        self.context = context
    }
}
