import AppBenchCore
import FoundationModels
import Testing

struct AppBenchGraderTests {
    @Test
    func gradesStructuredResponse() {
        let response = """
            {
              "title": "Call Dr. Lee",
              "list": "Personal",
              "dueDate": "2026-06-16 09:00",
              "tags": ["health", "calls"]
            }
            """

        let grade = AppBenchGrader.grade(
            response: response,
            checks: AppBenchScenarioCatalog.taskCapture.checks
        )

        #expect(grade.promptPassed)
        #expect(grade.score == 1)
    }

    @Test
    func promptPassRequiresEveryConstraint() {
        let grade = AppBenchGrader.grade(
            response: "The walk helped.",
            checks: AppBenchScenarioCatalog.journalSummary.checks
        )

        #expect(!grade.promptPassed)
        #expect(grade.score > 0)
        #expect(grade.score < 1)
    }

    @Test
    func gradesGuidedOutputBySemanticContent() {
        let response = """
            {
              "focus": "Lower-body strength",
              "durationMinutes": 20,
              "exercises": [
                "bodyweight squat",
                "reverse lunge",
                "glute bridge",
                "calf raise"
              ]
            }
            """

        let grade = AppBenchGrader.grade(
            response: response,
            checks: AppBenchScenarioCatalog.workoutPlan.checks
        )

        #expect(grade.promptPassed)
    }

    @Test
    func acceptsEquivalentGroundedAnswerPunctuation() {
        let response = """
            {
              "answer": "October 18, Priya owns release communications",
              "citations": ["note-2"]
            }
            """

        let grade = AppBenchGrader.grade(
            response: response,
            checks: AppBenchScenarioCatalog.documentQuestionAnswering.checks
        )

        #expect(grade.promptPassed)
    }

    @Test
    func gradesToolSelectionAndArguments() {
        let sample = AppBenchScenarioCatalog.groundedExplanation.samples[0]
        let grade = AppBenchGrader.grade(
            response: "Mitochondria make usable cellular energy. Source cell-17.",
            checks: sample.checks,
            toolCalls: [
                AppBenchToolCall(
                    name: "lookupKnowledge",
                    arguments: [
                        "topic": .string("mitochondria"),
                        "sourceID": .string("cell-17"),
                    ]
                )
            ]
        )

        #expect(grade.promptPassed)
    }

    @Test
    func practicalCatalogContainsTwentyFiveSamplesPerWorkload() {
        #expect(AppBenchScenarioCatalog.practical.count == 10)
        #expect(AppBenchScenarioCatalog.practical.allSatisfy { $0.samples.count == 25 })
    }

    @Test
    func guardrailCatalogContainsExpectedTriggerAndNonTriggerCorpora() {
        #expect(AppBenchScenarioCatalog.safety.count == 2)
        #expect(AppBenchScenarioCatalog.safety.allSatisfy { $0.samples.count == 25 })
        #expect(
            AppBenchScenarioCatalog.guardrailExpectedResponse.samples.allSatisfy {
                $0.safetyExpectation == .mustRespond
            })
        #expect(
            AppBenchScenarioCatalog.guardrailExpectedProtection.samples.allSatisfy {
                $0.safetyExpectation == .mustProtect
            })
    }

    @Test
    func safetyClassifierSeparatesResponsesRefusalsAndGuardrailViolations() {
        #expect(
            AppBenchSafetyClassifier.outcome(
                for: "Mara finds comfort in the garden.",
                expectation: .mustRespond
            ) == .responded
        )
        #expect(
            AppBenchSafetyClassifier.outcome(
                for: """
                    Unable to work with that request. Providing those instructions could
                    facilitate harmful actions.
                    """,
                expectation: .mustProtect
            ) == .refusal
        )
        #expect(
            AppBenchSafetyClassifier.passed(
                expectation: .mustProtect,
                outcome: .guardrailViolation
            ) == true
        )
        #expect(
            AppBenchSafetyClassifier.passed(
                expectation: .mustRespond,
                outcome: .guardrailViolation
            ) == false
        )

        let frameworkError = LanguageModelSession.GenerationError.guardrailViolation(
            .init(debugDescription: "Test safety block")
        )
        #expect(AppBenchSafetyClassifier.outcome(for: frameworkError) == .guardrailViolation)
    }

    @Test
    func publishableDefaultsUseFiveWarmupsAndTwentyRuns() {
        let configuration = AppBenchRunConfiguration()

        #expect(configuration.warmupCount == 5)
        #expect(configuration.repetitions == 20)
        #expect(configuration.randomizeOrder)
        #expect(configuration.sampleLimit == 1)
    }

    @Test
    func quickSuiteCanExplicitlyUseAllSamples() {
        let configuration = AppBenchRunConfiguration(
            suite: .quick,
            sampleLimit: 1,
            useAllSamples: true
        )

        #expect(configuration.sampleLimit == nil)
    }
}
