import Foundation

public struct AppBenchTrialResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let scenarioTitle: String
    public let category: AppBenchScenarioCategory
    public let sample: AppBenchSample
    public let requestedModel: AppBenchModel
    public let executedModel: AppBenchModel
    public let iteration: Int
    public let usedFallback: Bool
    public let fallbackReason: String?
    public let offlineSuccess: Bool
    public let toolCalls: [AppBenchToolCall]
    public let response: String
    public let grade: AppBenchGrade
    public let metrics: AppBenchTrialMetrics
    public let environment: EnvironmentSnapshot

    public init(
        id: UUID = UUID(),
        scenario: AppBenchScenario,
        sample: AppBenchSample,
        requestedModel: AppBenchModel,
        executedModel: AppBenchModel,
        iteration: Int,
        usedFallback: Bool = false,
        fallbackReason: String? = nil,
        offlineSuccess: Bool = false,
        toolCalls: [AppBenchToolCall] = [],
        response: String,
        grade: AppBenchGrade,
        metrics: AppBenchTrialMetrics,
        environment: EnvironmentSnapshot
    ) {
        self.id = id
        self.scenarioID = scenario.id
        self.scenarioTitle = scenario.title
        self.category = scenario.category
        self.sample = sample
        self.requestedModel = requestedModel
        self.executedModel = executedModel
        self.iteration = iteration
        self.usedFallback = usedFallback
        self.fallbackReason = fallbackReason
        self.offlineSuccess = offlineSuccess
        self.toolCalls = toolCalls
        self.response = response
        self.grade = grade
        self.metrics = metrics
        self.environment = environment
    }
}

public struct AppBenchFailure: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let sampleID: String
    public let iteration: Int
    public let kind: String
    public let message: String

    public init(
        id: UUID = UUID(),
        scenarioID: String,
        sampleID: String,
        iteration: Int,
        kind: String,
        message: String
    ) {
        self.id = id
        self.scenarioID = scenarioID
        self.sampleID = sampleID
        self.iteration = iteration
        self.kind = kind
        self.message = message
    }
}

public struct AppBenchQuotaSnapshot: Codable, Sendable {
    public let status: String
    public let isApproachingLimit: Bool?
    public let isLimitReached: Bool
    public let resetDate: Date?

    public init(
        status: String,
        isApproachingLimit: Bool?,
        isLimitReached: Bool,
        resetDate: Date?
    ) {
        self.status = status
        self.isApproachingLimit = isApproachingLimit
        self.isLimitReached = isLimitReached
        self.resetDate = resetDate
    }
}

public struct AppBenchScenarioSummary: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: AppBenchScenarioCategory
    public let trialCount: Int
    public let failureCount: Int
    public let failureRate: Double
    public let promptPassRate: Double
    public let meanConstraintScore: Double
    public let duration: AppBenchDistribution
    public let timeToFirstToken: AppBenchDistribution
    public let outputTokensPerSecond: AppBenchDistribution
    public let peakObservedResidentMemoryBytes: AppBenchDistribution

    init(scenario: AppBenchScenario, trials: [AppBenchTrialResult], failureCount: Int) {
        id = scenario.id
        title = scenario.title
        category = scenario.category
        trialCount = trials.count
        self.failureCount = failureCount
        let attemptCount = trials.count + failureCount
        failureRate = attemptCount == 0 ? 0 : Double(failureCount) / Double(attemptCount)
        promptPassRate =
            trials.isEmpty
            ? 0
            : Double(trials.count(where: { $0.grade.promptPassed })) / Double(trials.count)
        meanConstraintScore =
            trials.isEmpty
            ? 0
            : trials.map(\.grade.score).reduce(0, +) / Double(trials.count)
        duration = AppBenchDistribution(values: trials.map(\.metrics.duration))
        timeToFirstToken = AppBenchDistribution(
            values: trials.compactMap(\.metrics.timeToFirstToken))
        outputTokensPerSecond = AppBenchDistribution(
            values: trials.compactMap(\.metrics.outputTokensPerSecond))
        peakObservedResidentMemoryBytes = AppBenchDistribution(
            values: trials.compactMap(\.metrics.peakObservedResidentMemoryBytes).map { Double($0) }
        )
    }
}

public struct AppBenchRunResult: Codable, Sendable {
    public let suite: AppBenchSuite
    public let model: AppBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let sampleLimit: Int?
    public let sessionMode: AppBenchSessionMode
    public let reasoningLevel: AppBenchReasoningLevel
    public let fallbackMode: AppBenchFallbackMode
    public let connectivity: AppBenchConnectivity
    public let randomizedOrder: Bool
    public let randomSeed: UInt64
    public let modelContextSize: Int?
    public let quotaBefore: AppBenchQuotaSnapshot?
    public let quotaAfter: AppBenchQuotaSnapshot?
    public let startedAt: Date
    public let endedAt: Date
    public let environment: EnvironmentSnapshot
    public let trials: [AppBenchTrialResult]
    public let failures: [AppBenchFailure]
    public let summaries: [AppBenchScenarioSummary]

    public init(
        suite: AppBenchSuite,
        model: AppBenchModel,
        warmupCount: Int,
        repetitions: Int,
        sampleLimit: Int?,
        sessionMode: AppBenchSessionMode,
        reasoningLevel: AppBenchReasoningLevel,
        fallbackMode: AppBenchFallbackMode,
        connectivity: AppBenchConnectivity,
        randomizedOrder: Bool,
        randomSeed: UInt64,
        modelContextSize: Int?,
        quotaBefore: AppBenchQuotaSnapshot?,
        quotaAfter: AppBenchQuotaSnapshot?,
        startedAt: Date,
        endedAt: Date,
        environment: EnvironmentSnapshot,
        trials: [AppBenchTrialResult],
        failures: [AppBenchFailure],
        scenarios: [AppBenchScenario]
    ) {
        self.suite = suite
        self.model = model
        self.warmupCount = warmupCount
        self.repetitions = repetitions
        self.sampleLimit = sampleLimit
        self.sessionMode = sessionMode
        self.reasoningLevel = reasoningLevel
        self.fallbackMode = fallbackMode
        self.connectivity = connectivity
        self.randomizedOrder = randomizedOrder
        self.randomSeed = randomSeed
        self.modelContextSize = modelContextSize
        self.quotaBefore = quotaBefore
        self.quotaAfter = quotaAfter
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.environment = environment
        self.trials = trials
        self.failures = failures
        self.summaries = scenarios.map { scenario in
            AppBenchScenarioSummary(
                scenario: scenario,
                trials: trials.filter { $0.scenarioID == scenario.id },
                failureCount: failures.count(where: { $0.scenarioID == scenario.id })
            )
        }
    }
}
