import Foundation
import FoundationModels

public struct AppBenchRunConfiguration: Sendable {
    public let suite: AppBenchSuite
    public let scenarios: [AppBenchScenario]
    public let model: AppBenchModel
    public let warmupCount: Int
    public let repetitions: Int

    public init(
        suite: AppBenchSuite = .quick,
        scenarios: [AppBenchScenario]? = nil,
        model: AppBenchModel = .onDevice,
        warmupCount: Int = 1,
        repetitions: Int = 3
    ) {
        self.suite = suite
        self.scenarios = scenarios ?? AppBenchScenarioCatalog.scenarios(for: suite)
        self.model = model
        self.warmupCount = max(0, warmupCount)
        self.repetitions = max(1, repetitions)
    }
}

public actor AppBenchRunner {
    public enum Error: Swift.Error, LocalizedError, Sendable {
        case onDeviceModelUnavailable(String)
        case privateCloudComputeRequiresXcode27
        case privateCloudComputeUnavailable(String)
        case emptyResponse

        public var errorDescription: String? {
            switch self {
            case .onDeviceModelUnavailable(let reason):
                "The on-device model is unavailable: \(reason)"
            case .privateCloudComputeRequiresXcode27:
                "Private Cloud Compute requires the OS 27 SDK and Xcode 27."
            case .privateCloudComputeUnavailable(let reason):
                "Private Cloud Compute is unavailable: \(reason)"
            case .emptyResponse:
                "The model returned an empty response."
            }
        }
    }

    private let configuration: AppBenchRunConfiguration

    public init(configuration: AppBenchRunConfiguration = .init()) {
        self.configuration = configuration
    }

    public func run() async throws -> AppBenchRunResult {
        try ensureAvailability()
        let startedAt = Date.now
        let environment = EnvironmentSnapshot.capture()

        for _ in 0 ..< configuration.warmupCount {
            try await warmUp()
        }

        var trials: [AppBenchTrialResult] = []
        var failures: [AppBenchFailure] = []

        for scenario in configuration.scenarios {
            for iteration in 1 ... configuration.repetitions {
                do {
                    trials.append(
                        try await run(
                            scenario: scenario,
                            iteration: iteration,
                            environment: environment
                        )
                    )
                } catch {
                    failures.append(
                        AppBenchFailure(
                            scenarioID: scenario.id,
                            iteration: iteration,
                            message: detailedMessage(for: error)
                        )
                    )
                }
            }
        }

        return AppBenchRunResult(
            suite: configuration.suite,
            model: configuration.model,
            warmupCount: configuration.warmupCount,
            repetitions: configuration.repetitions,
            startedAt: startedAt,
            endedAt: .now,
            environment: environment,
            trials: trials,
            failures: failures,
            scenarios: configuration.scenarios
        )
    }

    private func run(
        scenario: AppBenchScenario,
        iteration: Int,
        environment: EnvironmentSnapshot
    ) async throws -> AppBenchTrialResult {
        let session = try makeSession(instructions: scenario.instructions)
        let options = generationOptions(maximumResponseTokens: scenario.maximumResponseTokens)
        let startedAt = Date.now
        var firstTokenAt: Date?
        var response = ""
        var streamUpdateDates: [Date] = []

        switch scenario.outputMode {
        case .text:
            let stream = session.streamResponse(to: Prompt(scenario.prompt), options: options)
            do {
                for try await snapshot in stream {
                    let updateDate = Date.now
                    firstTokenAt = firstTokenAt ?? updateDate
                    streamUpdateDates.append(updateDate)
                    response = renderText(from: snapshot)
                }
            } catch is LanguageModelSession.GenerationError where !response.isEmpty {
                break
            }
        case .guided(let appBenchSchema):
            let schema = try AppBenchSchemaFactory.make(appBenchSchema)
            let stream = session.streamResponse(
                to: Prompt(scenario.prompt),
                schema: schema,
                options: options
            )
            for try await snapshot in stream {
                let updateDate = Date.now
                firstTokenAt = firstTokenAt ?? updateDate
                streamUpdateDates.append(updateDate)
                response = renderStructured(from: snapshot)
            }
        }

        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Error.emptyResponse
        }

        let endedAt = Date.now
        let promptText = scenario.instructions + "\n" + scenario.prompt
        let metrics = AppBenchTrialMetrics(
            startedAt: startedAt,
            endedAt: endedAt,
            firstTokenAt: firstTokenAt,
            promptTokenEstimate: estimateInputTokens(promptText),
            responseTokenEstimate: estimateOutputTokens(response),
            responseCharacterCount: response.count,
            streamUpdateDates: streamUpdateDates
        )

        return AppBenchTrialResult(
            scenario: scenario,
            model: configuration.model,
            iteration: iteration,
            response: response,
            grade: AppBenchGrader.grade(response: response, checks: scenario.checks),
            metrics: metrics,
            environment: environment
        )
    }

    private func warmUp() async throws {
        let session = try makeSession(instructions: "Follow the request exactly.")
        _ = try await session.respond(
            to: "Reply with READY.",
            options: generationOptions(maximumResponseTokens: 8)
        )
    }

    private func makeSession(instructions: String) throws -> LanguageModelSession {
        switch configuration.model {
        case .onDevice:
            return LanguageModelSession(
                model: SystemLanguageModel.default,
                instructions: Instructions(instructions)
            )
        case .privateCloudCompute:
            #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                return LanguageModelSession(
                    model: PrivateCloudComputeLanguageModel(),
                    instructions: Instructions(instructions)
                )
            }
            throw Error.privateCloudComputeRequiresXcode27
            #else
            throw Error.privateCloudComputeRequiresXcode27
            #endif
        }
    }

    private func ensureAvailability() throws {
        switch configuration.model {
        case .onDevice:
            if case .unavailable(let reason) = SystemLanguageModel.default.availability {
                throw Error.onDeviceModelUnavailable(String(describing: reason))
            }
        case .privateCloudCompute:
            #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                let model = PrivateCloudComputeLanguageModel()
                if case .unavailable(let reason) = model.availability {
                    throw Error.privateCloudComputeUnavailable(String(describing: reason))
                }
                return
            }
            throw Error.privateCloudComputeRequiresXcode27
            #else
            throw Error.privateCloudComputeRequiresXcode27
            #endif
        }
    }
}

private func detailedMessage(for error: any Swift.Error) -> String {
    let nsError = error as NSError
    let reflected = String(reflecting: error)
    let userInfo = nsError.userInfo.isEmpty ? "" : " userInfo=\(nsError.userInfo)"
    return "\(error.localizedDescription) [\(reflected); domain=\(nsError.domain) code=\(nsError.code)\(userInfo)]"
}

private func generationOptions(maximumResponseTokens: Int) -> GenerationOptions {
    #if compiler(>=6.4)
    GenerationOptions(
        samplingMode: .greedy,
        temperature: 0,
        maximumResponseTokens: maximumResponseTokens
    )
    #else
    GenerationOptions(
        sampling: .greedy,
        temperature: 0,
        maximumResponseTokens: maximumResponseTokens
    )
    #endif
}
