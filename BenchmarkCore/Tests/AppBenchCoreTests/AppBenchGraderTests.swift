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
            response: "Friday at 2 PM in Room 4B.",
            checks: AppBenchScenarioCatalog.notificationSummary.checks
        )

        #expect(!grade.promptPassed)
        #expect(grade.score > 0)
        #expect(grade.score < 1)
    }

    @Test
    func validatesArrayContentsAndCount() {
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
            checks: AppBenchScenarioCatalog.groundedDocumentAnswer.checks
        )

        #expect(grade.promptPassed)
    }
}
