import Foundation

public struct AppBenchSample: Codable, Identifiable, Sendable {
    public let id: String
    public let prompt: String
    public let checks: [AppBenchCheck]
    public let visualFixture: AppBenchVisualFixture?

    public init(
        id: String,
        prompt: String,
        checks: [AppBenchCheck],
        visualFixture: AppBenchVisualFixture? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.checks = checks
        self.visualFixture = visualFixture
    }
}

public struct AppBenchScenario: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: AppBenchScenarioCategory
    public let inspiredBy: [String]
    public let instructions: String
    public let outputMode: AppBenchOutputMode
    public let maximumResponseTokens: Int
    public let toolSet: AppBenchToolSet
    public let requiresOS27: Bool
    public let samples: [AppBenchSample]

    public var prompt: String { samples.first?.prompt ?? "" }
    public var checks: [AppBenchCheck] { samples.first?.checks ?? [] }

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
        checks: [AppBenchCheck],
        toolSet: AppBenchToolSet = .none,
        requiresOS27: Bool = false
    ) {
        self.init(
            id: id,
            title: title,
            summary: summary,
            category: category,
            inspiredBy: inspiredBy,
            instructions: instructions,
            outputMode: outputMode,
            maximumResponseTokens: maximumResponseTokens,
            toolSet: toolSet,
            requiresOS27: requiresOS27,
            samples: [.init(id: "\(id)-001", prompt: prompt, checks: checks)]
        )
    }

    public init(
        id: String,
        title: String,
        summary: String,
        category: AppBenchScenarioCategory,
        inspiredBy: [String],
        instructions: String,
        outputMode: AppBenchOutputMode,
        maximumResponseTokens: Int,
        toolSet: AppBenchToolSet = .none,
        requiresOS27: Bool = false,
        samples: [AppBenchSample]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.inspiredBy = inspiredBy
        self.instructions = instructions
        self.outputMode = outputMode
        self.maximumResponseTokens = maximumResponseTokens
        self.toolSet = toolSet
        self.requiresOS27 = requiresOS27
        self.samples = samples
    }
}
