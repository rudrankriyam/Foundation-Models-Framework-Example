import Foundation

public struct GenerateMultilingualResponsesRequest: CapabilityRequest {
    public let supportedLanguages: [SupportedLanguageDescriptor]?
    public let maximumResults: Int?
    public let context: CapabilityInvocationContext

    public init(
        supportedLanguages: [SupportedLanguageDescriptor]? = nil,
        maximumResults: Int? = nil,
        context: CapabilityInvocationContext
    ) {
        self.supportedLanguages = supportedLanguages
        self.maximumResults = maximumResults
        self.context = context
    }
}
