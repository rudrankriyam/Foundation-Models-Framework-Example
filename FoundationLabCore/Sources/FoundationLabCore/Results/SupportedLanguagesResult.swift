import Foundation

public struct SupportedLanguageDescriptor: Sendable, Hashable, Codable, Identifiable {
    public let identifier: String
    public let languageCode: String
    public let regionCode: String?

    public var id: String { identifier }

    public init(identifier: String, languageCode: String, regionCode: String?) {
        self.identifier = identifier
        self.languageCode = languageCode
        self.regionCode = regionCode
    }
}

public struct SupportedLanguagesResult: CapabilityResult, Sendable, Hashable, Codable {
    public let languages: [SupportedLanguageDescriptor]
    public let metadata: CapabilityExecutionMetadata

    public init(
        languages: [SupportedLanguageDescriptor],
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.languages = languages
        self.metadata = metadata
    }
}
