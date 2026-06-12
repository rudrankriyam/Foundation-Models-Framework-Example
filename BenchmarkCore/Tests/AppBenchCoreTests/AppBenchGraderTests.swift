import AppBenchCore
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
    func publishableDefaultsUseFiveWarmupsAndTwentyRuns() {
        let configuration = AppBenchRunConfiguration()

        #expect(configuration.warmupCount == 5)
        #expect(configuration.repetitions == 20)
        #expect(configuration.randomizeOrder)
        #expect(configuration.sampleLimit == 1)
    }
}
