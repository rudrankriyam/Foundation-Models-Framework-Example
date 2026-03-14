import Foundation

public struct RunSchemaExampleRequest: CapabilityRequest {
    public let example: FoundationLabSchemaExample
    public let presetIndex: Int
    public let input: String
    public let minimumElements: Int?
    public let maximumElements: Int?
    public let customChoices: [String]?
    public let generationOptions: FoundationLabGenerationOptions?
    public let context: CapabilityInvocationContext

    public init(
        example: FoundationLabSchemaExample,
        presetIndex: Int = 0,
        input: String,
        minimumElements: Int? = nil,
        maximumElements: Int? = nil,
        customChoices: [String]? = nil,
        generationOptions: FoundationLabGenerationOptions? = FoundationLabGenerationOptions(temperature: 0.1),
        context: CapabilityInvocationContext
    ) {
        self.example = example
        self.presetIndex = presetIndex
        self.input = input
        self.minimumElements = minimumElements
        self.maximumElements = maximumElements
        self.customChoices = customChoices
        self.generationOptions = generationOptions
        self.context = context
    }
}
