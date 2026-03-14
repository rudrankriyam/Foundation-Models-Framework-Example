import Foundation

public struct GenerateMultilingualResponsesUseCase: CapabilityUseCase {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.generate-multilingual-responses",
        displayName: "Generate Multilingual Responses",
        summary: "Generates a set of short multilingual responses using Foundation Models."
    )

    private let textGenerator: GenerateTextUseCase
    private let supportedLanguages: ListSupportedLanguagesUseCase

    public init(
        textGenerator: GenerateTextUseCase = GenerateTextUseCase(),
        supportedLanguages: ListSupportedLanguagesUseCase = ListSupportedLanguagesUseCase()
    ) {
        self.textGenerator = textGenerator
        self.supportedLanguages = supportedLanguages
    }

    public func execute(
        _ request: GenerateMultilingualResponsesRequest
    ) async throws -> GenerateMultilingualResponsesResult {
        let languageDescriptors = request.supportedLanguages
            ?? supportedLanguages.execute(locale: .current).languages
        let prompts = FoundationLabLanguageCatalog.multilingualPrompts(
            using: languageDescriptors,
            locale: .current,
            limit: request.maximumResults
        )

        var responses: [MultilingualResponseEntry] = []
        var totalTokenCount = 0
        var successfulResponses = 0

        for prompt in prompts {
            do {
                let response = try await textGenerator.execute(
                    TextGenerationRequest(
                        prompt: prompt.text,
                        context: request.context
                    )
                )
                responses.append(
                    MultilingualResponseEntry(
                        language: prompt.language,
                        flag: prompt.flag,
                        prompt: prompt.text,
                        response: response.content,
                        isError: false,
                        metadata: response.metadata
                    )
                )

                if let tokenCount = response.metadata.tokenCount {
                    totalTokenCount += tokenCount
                }
                successfulResponses += 1
            } catch {
                responses.append(
                    MultilingualResponseEntry(
                        language: prompt.language,
                        flag: prompt.flag,
                        prompt: prompt.text,
                        response: error.localizedDescription,
                        isError: true
                    )
                )
            }
        }

        let aggregatedMetadata = CapabilityExecutionMetadata(
            provider: successfulResponses > 0 ? "Foundation Models" : nil,
            modelIdentifier: nil,
            tokenCount: successfulResponses > 0 ? totalTokenCount : nil
        )

        return GenerateMultilingualResponsesResult(
            prompts: prompts,
            responses: responses,
            metadata: aggregatedMetadata
        )
    }
}
