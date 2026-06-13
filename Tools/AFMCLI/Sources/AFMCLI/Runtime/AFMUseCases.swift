import Foundation
import FoundationModels

struct CheckModelAvailabilityUseCase: Sendable {
    static let descriptor = AFMCapabilityDescriptor(
        id: "afm.check-availability",
        displayName: "Check Model Availability",
        summary: "Checks whether Apple Intelligence is currently available."
    )

    private let checker: any AFMModelAvailabilityChecking

    init(checker: any AFMModelAvailabilityChecking = AFMFoundationModelsAvailabilityChecker()) {
        self.checker = checker
    }

    func execute(useCase: AFMModelUseCase = .general) -> AFMAvailabilityResult {
        checker.currentAvailability(useCase: useCase)
    }
}

struct ListSupportedLanguagesUseCase: Sendable {
    static let descriptor = AFMCapabilityDescriptor(
        id: "afm.list-supported-languages",
        displayName: "List Supported Languages",
        summary: "Lists languages supported by the current Foundation Models runtime."
    )

    private let lister: any AFMSupportedLanguageListing

    init(lister: any AFMSupportedLanguageListing = AFMFoundationModelsSupportedLanguageLister()) {
        self.lister = lister
    }

    func execute(useCase: AFMModelUseCase = .general, locale: Locale = .current) -> AFMSupportedLanguagesResult {
        lister.supportedLanguages(useCase: useCase, locale: locale)
    }
}

struct GenerateTextUseCase: AFMCapabilityUseCase {
    static let descriptor = AFMCapabilityDescriptor(
        id: "afm.generate-text",
        displayName: "Generate Text",
        summary: "Generates text from a prompt using Foundation Models."
    )

    private let provider: any AFMTextGenerationProviding

    init(provider: any AFMTextGenerationProviding = AFMFoundationModelsTextGenerator()) {
        self.provider = provider
    }

    func execute(_ request: AFMTextGenerationRequest) async throws -> AFMTextGenerationResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        return try await provider.generateText(for: request)
    }
}

struct StreamTextGenerationUseCase: Sendable {
    static let descriptor = AFMCapabilityDescriptor(
        id: "afm.stream-text",
        displayName: "Stream Text",
        summary: "Streams text generation updates using Foundation Models."
    )

    private let provider: any AFMStreamingTextGenerationProviding

    init(provider: any AFMStreamingTextGenerationProviding = AFMFoundationModelsStreamingTextGenerator()) {
        self.provider = provider
    }

    func execute(
        _ request: AFMStreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) async -> Void
    ) async throws -> AFMTextGenerationResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        return try await provider.streamText(for: request, onPartialResponse: onPartialResponse)
    }
}

struct GenerateStructuredDataUseCase<Output: Generable & Sendable>: AFMCapabilityUseCase {
    static var descriptor: AFMCapabilityDescriptor {
        AFMCapabilityDescriptor(
            id: "afm.generate-structured-data",
            displayName: "Generate Structured Data",
            summary: "Generates type-safe structured data using Foundation Models."
        )
    }

    private let provider: any AFMStructuredGenerationProviding

    init(provider: any AFMStructuredGenerationProviding = AFMFoundationModelsStructuredGenerator()) {
        self.provider = provider
    }

    func execute(_ request: AFMStructuredGenerationRequest<Output>) async throws -> AFMStructuredGenerationResult<Output> {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        return try await provider.generate(Output.self, for: request)
    }
}

struct GenerateDynamicSchemaContentUseCase: AFMCapabilityUseCase {
    static let descriptor = AFMCapabilityDescriptor(
        id: "afm.generate-dynamic-schema",
        displayName: "Generate Dynamic Schema Content",
        summary: "Generates content using a runtime-defined schema."
    )

    private let provider: any AFMDynamicSchemaGenerationProviding

    init(provider: any AFMDynamicSchemaGenerationProviding = AFMFoundationModelsDynamicSchemaGenerator()) {
        self.provider = provider
    }

    func execute(_ request: AFMDynamicSchemaGenerationRequest) async throws -> AFMDynamicSchemaGenerationResult {
        guard !request.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }

        return try await provider.generate(for: request)
    }
}
