import Foundation
import FoundationModelsTools

public struct FoundationModelsLocationResponder: LocationResponding {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func getCurrentLocation(for request: GetCurrentLocationRequest) async throws -> TextGenerationResult {
        try await toolInvoker.respond(
            to: "What's my current location?",
            using: LocationTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
