import Foundation
import FoundationModels

extension AFMModelUseCase {
    var foundationModelsValue: SystemLanguageModel.UseCase {
        switch self {
        case .general:
            .general
        case .contentTagging:
            .contentTagging
        }
    }
}

extension AFMGuardrails {
    var foundationModelsValue: SystemLanguageModel.Guardrails {
        switch self {
        case .default:
            .default
        case .permissiveContentTransformations:
            .permissiveContentTransformations
        }
    }
}

extension AFMFeedbackIssueCategory {
    var foundationModelsValue: LanguageModelFeedback.Issue.Category {
        switch self {
        case .unhelpful:
            .unhelpful
        case .tooVerbose:
            .tooVerbose
        case .didNotFollowInstructions:
            .didNotFollowInstructions
        case .incorrect:
            .incorrect
        case .stereotypeOrBias:
            .stereotypeOrBias
        case .suggestiveOrSexual:
            .suggestiveOrSexual
        case .vulgarOrOffensive:
            .vulgarOrOffensive
        case .triggeredGuardrailUnexpectedly:
            .triggeredGuardrailUnexpectedly
        }
    }
}

extension AFMGenerationOptions.SamplingMode {
    var foundationModelsValue: GenerationOptions.SamplingMode {
        switch self {
        case .greedy:
            .greedy
        case .randomTop(let top, let seed):
            .random(top: top, seed: seed)
        case .randomProbabilityThreshold(let threshold, let seed):
            .random(probabilityThreshold: threshold, seed: seed)
        }
    }
}

extension AFMGenerationOptions {
    var foundationModelsValue: GenerationOptions {
        GenerationOptions(
            sampling: sampling?.foundationModelsValue,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }
}

struct AFMFoundationModelsAvailabilityChecker: AFMModelAvailabilityChecking {
    func currentAvailability(useCase: AFMModelUseCase = .general) -> AFMAvailabilityResult {
        let model = makeModel(useCase: useCase, guardrails: .default)
        switch model.availability {
        case .available:
            return AFMAvailabilityResult(
                isAvailable: true,
                metadata: AFMExecutionMetadata(provider: "Foundation Models", modelIdentifier: useCase.rawValue)
            )
        case .unavailable(let reason):
            return AFMAvailabilityResult(
                isAvailable: false,
                reason: map(reason),
                metadata: AFMExecutionMetadata(provider: "Foundation Models", modelIdentifier: useCase.rawValue)
            )
        }
    }

    private func map(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> AFMAvailabilityUnavailableReason {
        switch reason {
        case .deviceNotEligible:
            .deviceNotEligible
        case .appleIntelligenceNotEnabled:
            .appleIntelligenceNotEnabled
        case .modelNotReady:
            .modelNotReady
        @unknown default:
            .unknown
        }
    }
}

struct AFMFoundationModelsSupportedLanguageLister: AFMSupportedLanguageListing {
    func supportedLanguages(useCase: AFMModelUseCase = .general, locale: Locale = .current) -> AFMSupportedLanguagesResult {
        let model = makeModel(useCase: useCase, guardrails: .default)
        let languages = model.supportedLanguages.map { language in
            AFMSupportedLanguageDescriptor(
                identifier: language.maximalIdentifier,
                languageCode: language.languageCode?.identifier ?? "",
                regionCode: language.region?.identifier
            )
        }

        return AFMSupportedLanguagesResult(
            languages: languages,
            metadata: AFMExecutionMetadata(provider: "Foundation Models", modelIdentifier: useCase.rawValue)
        )
    }
}

struct AFMFoundationModelsTextGenerator: AFMTextGenerationProviding {
    func generateText(for request: AFMTextGenerationRequest) async throws -> AFMTextGenerationResult {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        let model = makeModel(useCase: request.modelUseCase, guardrails: request.guardrails)
        let session = makeSession(model: model, systemPrompt: request.systemPrompt)

        let responseContent: String
        if let generationOptions = request.generationOptions {
            responseContent = try await session.respond(
                to: Prompt(prompt),
                options: generationOptions.foundationModelsValue
            ).content
        } else {
            responseContent = try await session.respond(to: Prompt(prompt)).content
        }

        let tokenCount = await session.transcript.afmTokenCount(using: model)
        return AFMTextGenerationResult(
            content: responseContent,
            metadata: AFMExecutionMetadata(provider: "Foundation Models", tokenCount: tokenCount)
        )
    }
}

struct AFMFoundationModelsStreamingTextGenerator: AFMStreamingTextGenerationProviding {
    func streamText(
        for request: AFMStreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) async -> Void
    ) async throws -> AFMTextGenerationResult {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        let model = makeModel(useCase: request.modelUseCase, guardrails: request.guardrails)
        let session = makeSession(model: model, systemPrompt: request.systemPrompt)

        var finalContent = ""
        if let generationOptions = request.generationOptions {
            for try await partialResponse in session.streamResponse(
                to: Prompt(prompt),
                options: generationOptions.foundationModelsValue
            ) {
                finalContent = partialResponse.content
                await onPartialResponse(partialResponse.content)
            }
        } else {
            for try await partialResponse in session.streamResponse(to: Prompt(prompt)) {
                finalContent = partialResponse.content
                await onPartialResponse(partialResponse.content)
            }
        }

        let tokenCount = await session.transcript.afmTokenCount(using: model)
        return AFMTextGenerationResult(
            content: finalContent,
            metadata: AFMExecutionMetadata(provider: "Foundation Models", tokenCount: tokenCount)
        )
    }
}

struct AFMFoundationModelsStructuredGenerator: AFMStructuredGenerationProviding {
    func generate<Output: Generable & Sendable>(
        _ type: Output.Type,
        for request: AFMStructuredGenerationRequest<Output>
    ) async throws -> AFMStructuredGenerationResult<Output> {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        let model = makeModel(useCase: request.modelUseCase, guardrails: request.guardrails)
        let session = makeSession(model: model, systemPrompt: request.systemPrompt)
        let response: LanguageModelSession.Response<Output>

        if let generationOptions = request.generationOptions {
            response = try await session.respond(
                to: Prompt(prompt),
                generating: type,
                includeSchemaInPrompt: request.includeSchemaInPrompt,
                options: generationOptions.foundationModelsValue
            )
        } else {
            response = try await session.respond(
                to: Prompt(prompt),
                generating: type,
                includeSchemaInPrompt: request.includeSchemaInPrompt
            )
        }

        let tokenCount = await session.transcript.afmTokenCount(using: model)
        return AFMStructuredGenerationResult(
            output: response.content,
            metadata: AFMExecutionMetadata(provider: "Foundation Models", tokenCount: tokenCount)
        )
    }
}

struct AFMFoundationModelsDynamicSchemaGenerator: AFMDynamicSchemaGenerationProviding {
    func generate(for request: AFMDynamicSchemaGenerationRequest) async throws -> AFMDynamicSchemaGenerationResult {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        let model = makeModel(useCase: request.modelUseCase, guardrails: request.guardrails)
        let session = makeSession(model: model, systemPrompt: request.systemPrompt)
        let output: GeneratedContent

        if let generationOptions = request.generationOptions {
            output = try await session.respond(
                to: Prompt(prompt),
                schema: request.schema,
                includeSchemaInPrompt: request.includeSchemaInPrompt,
                options: generationOptions.foundationModelsValue
            ).content
        } else {
            output = try await session.respond(
                to: Prompt(prompt),
                schema: request.schema,
                includeSchemaInPrompt: request.includeSchemaInPrompt
            ).content
        }

        let tokenCount = await session.transcript.afmTokenCount(using: model)
        return AFMDynamicSchemaGenerationResult(
            output: output,
            metadata: AFMExecutionMetadata(provider: "Foundation Models", tokenCount: tokenCount)
        )
    }
}

private func makeModel(useCase: AFMModelUseCase, guardrails: AFMGuardrails?) -> SystemLanguageModel {
    SystemLanguageModel(
        useCase: useCase.foundationModelsValue,
        guardrails: (guardrails ?? .default).foundationModelsValue
    )
}

private func makeSession(model: SystemLanguageModel, systemPrompt: String?) -> LanguageModelSession {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        return LanguageModelSession(model: model, instructions: Instructions(trimmedSystemPrompt))
    }
    return LanguageModelSession(model: model)
}
