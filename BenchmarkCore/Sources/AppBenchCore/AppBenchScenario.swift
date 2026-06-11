import Foundation

public struct AppBenchScenario: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: AppBenchScenarioCategory
    public let inspiredBy: [String]
    public let instructions: String
    public let prompt: String
    public let outputMode: AppBenchOutputMode
    public let maximumResponseTokens: Int
    public let checks: [AppBenchCheck]

    public init(
        id: String,
        title: String,
        summary: String,
        category: AppBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        prompt: String,
        outputMode: AppBenchOutputMode,
        maximumResponseTokens: Int,
        checks: [AppBenchCheck]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.inspiredBy = inspiredBy
        self.instructions = instructions
        self.prompt = prompt
        self.outputMode = outputMode
        self.maximumResponseTokens = maximumResponseTokens
        self.checks = checks
    }
}
