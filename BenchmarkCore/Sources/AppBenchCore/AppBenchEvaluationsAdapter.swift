#if canImport(Evaluations) && compiler(>=6.4)
    import Evaluations
    import FoundationModels

    @available(macOS 27.0, iOS 27.0, visionOS 27.0, *)
    public enum AppBenchEvaluationsAdapter {
        public static let promptPassMetric = Metric("appbench-prompt-pass")
        public static let constraintScoreMetric = Metric("appbench-constraint-score")
        public static let toolCallsPassMetric = Metric("appbench-tool-calls-pass")
        public static let toolCallsPercentageMetric = Metric("appbench-tool-calls-percentage")

        public static func samples(for scenario: AppBenchScenario) throws -> [ModelSample<String>] {
            let schema: GenerationSchema?
            switch scenario.outputMode {
            case .text:
                schema = nil
            case .guided(let appBenchSchema):
                schema = try AppBenchSchemaFactory.make(appBenchSchema)
            }

            return try scenario.samples.map { sample in
                let prompt = try appBenchPrompt(for: sample)
                return ModelSample(
                    prompt: prompt,
                    expected: sample.id,
                    instructions: Instructions(scenario.instructions),
                    generationSchema: schema,
                    expectations: trajectoryExpectation(for: sample.checks)
                )
            }
        }

        public static func promptPassEvaluator(
            for scenario: AppBenchScenario
        ) -> Evaluator<ModelSample<String>> {
            let checks = checksBySampleID(scenario)
            return Evaluator { input, subject in
                guard let sampleID = input.expected, let sampleChecks = checks[sampleID] else {
                    return promptPassMetric.ignore(rationale: "Missing AppBench sample metadata.")
                }
                let grade = AppBenchGrader.grade(
                    response: subject.value,
                    checks: sampleChecks.filter { !$0.isToolCheck }
                )
                return grade.promptPassed
                    ? promptPassMetric.passing()
                    : promptPassMetric.failing(rationale: failedCheckRationale(grade))
            }
        }

        public static func constraintScoreEvaluator(
            for scenario: AppBenchScenario
        ) -> Evaluator<ModelSample<String>> {
            let checks = checksBySampleID(scenario)
            return Evaluator { input, subject in
                guard let sampleID = input.expected, let sampleChecks = checks[sampleID] else {
                    return constraintScoreMetric.ignore(
                        rationale: "Missing AppBench sample metadata.")
                }
                let grade = AppBenchGrader.grade(
                    response: subject.value,
                    checks: sampleChecks.filter { !$0.isToolCheck }
                )
                return constraintScoreMetric.scoring(
                    grade.score,
                    rationale: failedCheckRationale(grade)
                )
            }
        }

        public static func toolCallEvaluator(
            for scenario: AppBenchScenario
        ) -> ToolCallEvaluator<ModelSample<String>>? {
            guard scenario.toolSet != .none else { return nil }
            return ToolCallEvaluator(
                allPass: toolCallsPassMetric,
                percentagePass: toolCallsPercentageMetric
            )
        }

        private static func checksBySampleID(_ scenario: AppBenchScenario) -> [String:
            [AppBenchCheck]]
        {
            Dictionary(uniqueKeysWithValues: scenario.samples.map { ($0.id, $0.checks) })
        }

        private static func trajectoryExpectation(
            for checks: [AppBenchCheck]
        ) -> TrajectoryExpectation? {
            let toolNames = checks.compactMap { check -> String? in
                if case .toolCalled(let name) = check { return name }
                return nil
            }
            guard let toolName = toolNames.first else { return nil }

            let arguments = checks.compactMap { check -> ArgumentMatcher? in
                guard
                    case .toolArgumentEquals(let tool, let argument, let value) = check,
                    tool == toolName
                else {
                    return nil
                }
                return .exact(argumentName: argument, value: argumentValue(value))
            }
            return TrajectoryExpectation(expected: toolName, arguments: arguments)
        }

        private static func argumentValue(_ value: AppBenchJSONValue) -> ArgumentValue {
            switch value {
            case .string(let value):
                .string(value)
            case .integer(let value):
                .int(value)
            case .number(let value):
                .double(value)
            case .boolean(let value):
                .bool(value)
            }
        }

        private static func failedCheckRationale(_ grade: AppBenchGrade) -> String? {
            let failures = grade.checks.filter { !$0.passed }.map(\.label)
            return failures.isEmpty ? nil : failures.joined(separator: "; ")
        }
    }
#endif
