import Foundation

public struct AppBenchTrialResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenario: AppBenchScenario
    public let model: AppBenchModel
    public let iteration: Int
    public let response: String
    public let grade: AppBenchGrade
    public let metrics: AppBenchTrialMetrics
    public let environment: EnvironmentSnapshot

    public init(
        id: UUID = UUID(),
        scenario: AppBenchScenario,
        model: AppBenchModel,
        iteration: Int,
        response: String,
        grade: AppBenchGrade,
        metrics: AppBenchTrialMetrics,
        environment: EnvironmentSnapshot
    ) {
        self.id = id
        self.scenario = scenario
        self.model = model
        self.iteration = iteration
        self.response = response
        self.grade = grade
        self.metrics = metrics
        self.environment = environment
    }
}

public struct AppBenchFailure: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let iteration: Int
    public let message: String

    public init(id: UUID = UUID(), scenarioID: String, iteration: Int, message: String) {
        self.id = id
        self.scenarioID = scenarioID
        self.iteration = iteration
        self.message = message
    }
}

public struct AppBenchScenarioSummary: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: AppBenchScenarioCategory
    public let trialCount: Int
    public let failureCount: Int
    public let promptPassRate: Double
    public let meanConstraintScore: Double
    public let duration: AppBenchDistribution
    public let timeToFirstToken: AppBenchDistribution
    public let outputTokensPerSecond: AppBenchDistribution

    init(scenario: AppBenchScenario, trials: [AppBenchTrialResult], failureCount: Int) {
        id = scenario.id
        title = scenario.title
        category = scenario.category
        trialCount = trials.count
        self.failureCount = failureCount
        promptPassRate = trials.isEmpty
            ? 0
            : Double(trials.count(where: { $0.grade.promptPassed })) / Double(trials.count)
        meanConstraintScore = trials.isEmpty
            ? 0
            : trials.map(\.grade.score).reduce(0, +) / Double(trials.count)
        duration = AppBenchDistribution(values: trials.map(\.metrics.duration))
        timeToFirstToken = AppBenchDistribution(values: trials.compactMap(\.metrics.timeToFirstToken))
        outputTokensPerSecond = AppBenchDistribution(values: trials.compactMap(\.metrics.outputTokensPerSecond))
    }
}

public struct AppBenchRunResult: Codable, Sendable {
    public let suite: AppBenchSuite
    public let model: AppBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let startedAt: Date
    public let endedAt: Date
    public let trials: [AppBenchTrialResult]
    public let failures: [AppBenchFailure]
    public let summaries: [AppBenchScenarioSummary]

    public init(
        suite: AppBenchSuite,
        model: AppBenchModel,
        warmupCount: Int,
        repetitions: Int,
        startedAt: Date,
        endedAt: Date,
        trials: [AppBenchTrialResult],
        failures: [AppBenchFailure],
        scenarios: [AppBenchScenario]
    ) {
        self.suite = suite
        self.model = model
        self.warmupCount = warmupCount
        self.repetitions = repetitions
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.trials = trials
        self.failures = failures
        self.summaries = scenarios.map { scenario in
            AppBenchScenarioSummary(
                scenario: scenario,
                trials: trials.filter { $0.scenario.id == scenario.id },
                failureCount: failures.count(where: { $0.scenarioID == scenario.id })
            )
        }
    }
}
