import Foundation

public enum AppBenchScenarioCatalog {
    public static let all: [AppBenchScenario] = [
        taskCapture,
        notificationSummary,
        journalSummary,
        habitClassification,
        workoutPlan,
        groundedDocumentAnswer,
        syntheticThroughput
    ]

    public static func scenarios(for suite: AppBenchSuite) -> [AppBenchScenario] {
        switch suite {
        case .quick:
            [taskCapture, notificationSummary, habitClassification, workoutPlan, groundedDocumentAnswer]
        case .full:
            all.filter { $0.category != .syntheticThroughput }
        case .performance:
            [syntheticThroughput]
        }
    }

    public static let taskCapture = AppBenchScenario(
        id: "task-capture",
        title: "Natural-language task capture",
        summary: "Extracts a task, list, date, and tags from conversational input.",
        category: .taskParsing,
        inspiredBy: ["Stuff", "OmniFocus"],
        instructions: """
        Extract task information exactly from the request. Never invent missing details.
        Use the supplied reference date and the requested date format.
        """,
        prompt: """
        Reference date: 2026-06-12.
        Request: Add “Call Dr. Lee” to my Personal list for June 16, 2026 at 9:00 AM.
        Tag it with health and calls.
        Return dueDate in the exact format YYYY-MM-DD HH:mm.
        """,
        outputMode: .guided(.task),
        maximumResponseTokens: 120,
        checks: [
            .jsonEquals(path: "title", value: .string("Call Dr. Lee")),
            .jsonEquals(path: "list", value: .string("Personal")),
            .jsonEquals(path: "dueDate", value: .string("2026-06-16 09:00")),
            .jsonContains(path: "tags", values: ["health", "calls"])
        ]
    )

    public static let notificationSummary = AppBenchScenario(
        id: "notification-summary",
        title: "Stacked notification summary",
        summary: "Compresses a message stack while preserving decisions and actions.",
        category: .summarization,
        inspiredBy: ["Stoic", "Gratitude"],
        instructions: """
        Summarize only the supplied messages. Preserve decisions, times, locations, and
        required actions. Do not add facts. Use no more than 45 words.
        """,
        prompt: """
        Maya: The launch review moved to Friday at 2 PM in Room 4B.
        Theo: I uploaded the final deck. Please check slides 8 and 11 before the meeting.
        Maya: Finance approved the budget, so no approval is blocking launch.
        """,
        outputMode: .text,
        maximumResponseTokens: 96,
        checks: [
            .contains("Friday"),
            .contains("2 PM"),
            .contains("Room 4B"),
            .contains("8"),
            .contains("11"),
            .contains("budget"),
            .maximumWords(45)
        ]
    )

    public static let journalSummary = AppBenchScenario(
        id: "journal-summary",
        title: "Grounded journal reflection",
        summary: "Produces a concise reflection without diagnosing or inventing events.",
        category: .summarization,
        inspiredBy: ["Stoic", "Gratitude"],
        instructions: """
        Write a two-sentence reflection grounded only in the journal entry.
        Mention one positive moment and one practical next step. Do not diagnose the writer.
        """,
        prompt: """
        I felt rushed this morning, but the walk after lunch helped me reset.
        I finished the client proposal and enjoyed calling my sister.
        Tomorrow I want to start with the hardest task before checking messages.
        """,
        outputMode: .text,
        maximumResponseTokens: 100,
        checks: [
            .contains("walk"),
            .contains("hardest task"),
            .excludes("diagnos"),
            .maximumWords(70)
        ]
    )

    public static let habitClassification = AppBenchScenario(
        id: "habit-classification",
        title: "Habit category classification",
        summary: "Classifies an activity into one constrained application category.",
        category: .classification,
        inspiredBy: ["Motivation", "Streaks", "Vocabulary"],
        instructions: "Choose exactly one available category based on the primary user intent.",
        prompt: """
        Activity: Meditate for ten minutes before breakfast.
        Available categories: health, learning, productivity, relationships.
        """,
        outputMode: .guided(.classification),
        maximumResponseTokens: 32,
        checks: [
            .jsonEquals(path: "category", value: .string("health"))
        ]
    )

    public static let workoutPlan = AppBenchScenario(
        id: "workout-plan",
        title: "Constraint-aware workout plan",
        summary: "Builds a structured plan that obeys time, equipment, and exercise constraints.",
        category: .structuredRecommendation,
        inspiredBy: ["SmartGym", "7 Minute Workout", "Train Fitness"],
        instructions: """
        Follow every explicit constraint. Return concise exercise names and integer durations.
        """,
        prompt: """
        Create a 20-minute lower-body workout with no equipment.
        Use exactly four exercises: bodyweight squat, reverse lunge, glute bridge, and calf raise.
        """,
        outputMode: .guided(.workout),
        maximumResponseTokens: 220,
        checks: [
            .jsonContains(path: "focus", values: ["lower-body"]),
            .jsonEquals(path: "durationMinutes", value: .integer(20)),
            .jsonContains(
                path: "exercises",
                values: ["bodyweight squat", "reverse lunge", "glute bridge", "calf raise"]
            )
        ]
    )

    public static let groundedDocumentAnswer = AppBenchScenario(
        id: "grounded-document-answer",
        title: "Grounded document question answering",
        summary: "Answers from supplied documents and returns only supporting citations.",
        category: .groundedQuestionAnswering,
        inspiredBy: ["Signeasy", "Agenda", "Essayist", "CellWalk", "Platzi"],
        instructions: """
        Answer only from the supplied documents. If the answer is absent, say so.
        Cite only document IDs that directly support the answer.
        """,
        prompt: """
        [note-1] The beta begins October 4. Design review is September 28.
        [note-2] Public launch is scheduled for October 18. Priya owns release communications.
        [note-3] The support rotation starts after launch on October 21.

        Question: When is the public launch, and who owns release communications?
        """,
        outputMode: .guided(.groundedAnswer),
        maximumResponseTokens: 140,
        checks: [
            .jsonContains(path: "answer", values: ["October 18", "Priya", "release communications"]),
            .jsonContains(path: "citations", values: ["note-2"])
        ]
    )

    public static let syntheticThroughput = AppBenchScenario(
        id: "synthetic-throughput",
        title: "Synthetic sustained generation",
        summary: "Preserves the repository’s original long-generation speed workload.",
        category: .syntheticThroughput,
        inspiredBy: ["Original Foundation Models Framework Benchmark"],
        instructions: """
        Write exactly 12 numbered paragraphs. Each paragraph must contain 3 to 4 sentences.
        Continue until all 12 paragraphs are complete.
        """,
        prompt: """
        Explain how a consistent morning routine can support productivity.
        Cover planning, physical energy, focus, interruptions, and sustainable habit formation.
        """,
        outputMode: .text,
        maximumResponseTokens: 768,
        checks: [
            .minimumWords(300),
            .contains("12")
        ]
    )
}
