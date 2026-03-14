import Foundation

public struct MultilingualResponseEntry: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let language: String
    public let flag: String
    public let prompt: String
    public let response: String
    public let isError: Bool
    public let metadata: CapabilityExecutionMetadata?

    public init(
        id: UUID = UUID(),
        language: String,
        flag: String,
        prompt: String,
        response: String,
        isError: Bool,
        metadata: CapabilityExecutionMetadata? = nil
    ) {
        self.id = id
        self.language = language
        self.flag = flag
        self.prompt = prompt
        self.response = response
        self.isError = isError
        self.metadata = metadata
    }
}

public struct GenerateMultilingualResponsesResult: CapabilityResult, Sendable, Hashable, Codable {
    public let prompts: [LanguagePrompt]
    public let responses: [MultilingualResponseEntry]
    public let metadata: CapabilityExecutionMetadata

    public init(
        prompts: [LanguagePrompt],
        responses: [MultilingualResponseEntry],
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.prompts = prompts
        self.responses = responses
        self.metadata = metadata
    }
}
