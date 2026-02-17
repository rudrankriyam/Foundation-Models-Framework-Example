//
//  HealthChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels
import Observation
import SwiftData
import SwiftUI
import OSLog

@MainActor
@Observable
final class HealthChatViewModel {

    // Constants
    private let sessionTimeout: TimeInterval = AppConfiguration.Health.sessionTimeout
    private let logger = Logger(subsystem: "com.foundationlab.health", category: "HealthChatViewModel")

    // MARK: - Published Properties
    var isLoading: Bool = false
    var isSummarizing: Bool = false
    var sessionCount: Int = 1
    var currentHealthMetrics: [MetricType: Double] = [:]

    // MARK: - Token Usage Tracking
    private(set) var currentTokenCount: Int = 0
    private(set) var maxContextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    var tokenUsageFraction: Double {
        guard maxContextSize > 0 else { return 0 }
        return min(1.0, Double(currentTokenCount) / Double(maxContextSize))
    }

    // MARK: - Streaming Task
    private var streamingTask: Task<Void, Error>?

    // MARK: - Public Properties
    private(set) var session: LanguageModelSession
    private var modelContext: ModelContext?
    private let healthDataManager: HealthDataManager
    private let languageModel = SystemLanguageModel.default

    // MARK: - Tools
    private let tools: [any Tool] = [
        HealthDataTool(),
        HealthAnalysisTool()
    ]

    // MARK: - Initialization
    init(healthDataManager: HealthDataManager? = nil) {
        self.healthDataManager = healthDataManager ?? .shared
        self.session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(Self.baseInstructions)
        )

        Task {
            maxContextSize = await AppConfiguration.TokenManagement.contextSize(for: languageModel)
        }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Public Methods

    @MainActor
    func sendMessage(_ content: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Save user message to session history
            await saveMessageToSession(content, isFromUser: true)

            // Stream response from current session
            let responseStream = session.streamResponse(to: Prompt(content))

            var responseText = ""
            streamingTask?.cancel()
            let task = Task { @MainActor in
                for try await _ in responseStream {
                    // The streaming automatically updates the session transcript
                }
            }
            streamingTask = task
            defer { streamingTask = nil }
            do {
                try await task.value
            } catch is CancellationError {
                return
            }

            // Extract the response text from the transcript
            responseText = latestResponseText()

            // Save AI response to session history
            if !responseText.isEmpty {
                await saveMessageToSession(responseText, isFromUser: false)
            }

            await updateTokenCount()

            if shouldGenerateInsight(from: responseText) {
                await generateHealthInsight(from: responseText)
            }

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Handle context window exceeded by summarizing and creating new session
            await handleContextWindowExceeded(userMessage: content)

        } catch {
            logger.error("Failed to generate response: \(error.localizedDescription, privacy: .public)")
            let errorText = FoundationModelsErrorHandler.handleError(error)
            await saveMessageToSession(errorText, isFromUser: false)
        }

    }

    @MainActor
    func clearChat() {
        streamingTask?.cancel()
        streamingTask = nil
        sessionCount = 1
        currentTokenCount = 0
        session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(Self.baseInstructions)
        )
    }

    @MainActor
    func tearDown() {
        streamingTask?.cancel()
        streamingTask = nil
    }

    @MainActor
    func loadInitialHealthData() async {
        do {
            try await healthDataManager.fetchTodayHealthData()
        } catch {
            logger.error("Failed to load health data: \(error.localizedDescription, privacy: .public)")
            await saveMessageToSession(
                FoundationModelsErrorHandler.handleError(error),
                isFromUser: false
            )
        }

        currentHealthMetrics = [
            .steps: healthDataManager.todaySteps,
            .heartRate: healthDataManager.currentHeartRate,
            .sleep: healthDataManager.lastNightSleep,
            .activeEnergy: healthDataManager.todayActiveEnergy,
            .distance: healthDataManager.todayDistance
        ]
    }

}

private extension HealthChatViewModel {
    func updateTokenCount() async {
        currentTokenCount = await session.transcript.tokenCount(using: languageModel)
    }

    static let baseInstructions = """
    You are a friendly and knowledgeable health coach AI assistant.
    Based on the user's health data, provide personalized, encouraging responses.
    Be supportive and celebrate small wins. Use emojis occasionally.
    """

    func shouldGenerateInsight(from response: String) -> Bool {
        let insightKeywords = ["goal", "achieve", "progress", "improve", "recommend", "suggest", "tip", "advice"]
        return insightKeywords.contains { response.lowercased().contains($0) }
    }

    func createConversationText() -> String {
        ConversationContextBuilder.conversationText(
            from: session.transcript,
            userLabel: String(localized: "User:"),
            assistantLabel: String(localized: "Health AI:")
        )
    }

    func latestResponseText() -> String {
        for entry in session.transcript.reversed() {
            switch entry {
            case .response:
                return entry.textContent() ?? ""
            case .prompt:
                return ""
            default:
                continue
            }
        }
        return ""
    }

    func createNewSessionWithContext(summary: HealthConversationSummary) {
        let contextInstructions = ConversationContextBuilder.contextInstructions(
            baseInstructions: Self.baseInstructions,
            summary: summary.summary,
            keyTopics: summary.keyTopics,
            userPreferences: summary.userPreferences,
            continuationNote: "Continue the conversation naturally, referencing this context when relevant."
        )

        session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(contextInstructions)
        )
        sessionCount += 1
        currentTokenCount = 0
    }
}

@MainActor
private extension HealthChatViewModel {
    func saveMessageToSession(_ content: String, isFromUser: Bool) async {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<HealthSession>(
            sortBy: [SortDescriptor<HealthSession>(\.startDate, order: .reverse)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            let activeSession: HealthSession

            if let existingSession = sessions.first,
               existingSession.startDate.timeIntervalSinceNow > -sessionTimeout {
                activeSession = existingSession
            } else {
                activeSession = HealthSession(sessionType: .coaching)
                modelContext.insert(activeSession)
            }

            let message = BuddyMessage(content: content, isFromUser: isFromUser)
            activeSession.messages.append(message)

            try modelContext.save()
        } catch {
            logger.error("Failed to save message to session: \(error.localizedDescription, privacy: .public)")
        }
    }

    func generateHealthInsight(from response: String) async {
        guard let modelContext = modelContext else { return }

        let insight = HealthInsight(
            title: "AI Health Tip",
            content: response,
            category: .recommendation,
            priority: .medium,
            relatedMetrics: []
        )

        modelContext.insert(insight)

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save health insight: \(error.localizedDescription, privacy: .public)")
        }
    }

    func handleContextWindowExceeded(userMessage: String) async {
        isSummarizing = true

        do {
            let summary = try await generateConversationSummary()
            createNewSessionWithContext(summary: summary)
            isSummarizing = false

            try await respondWithNewSession(to: userMessage, shouldSaveUserMessage: false)
            await updateTokenCount()
        } catch {
            isSummarizing = false
            session = LanguageModelSession(
                tools: tools,
                instructions: Instructions(Self.baseInstructions)
            )
            currentTokenCount = 0
            let restartMessage = "I need to start a fresh conversation. Please repeat your question."
            await saveMessageToSession(restartMessage, isFromUser: false)
        }
    }

    func generateConversationSummary() async throws -> HealthConversationSummary {
        let summarySession = LanguageModelSession(
            instructions: Instructions(
                """
                You are an expert at summarizing health coaching conversations.
                Create comprehensive summaries that preserve all health metrics discussed,
                goals set, and advice given.
                """
            )
        )

        let conversationText = createConversationText()
        let summaryPrompt = """
        Please summarize the following health coaching conversation.
        Include all health metrics discussed, goals mentioned, advice given, and user's health concerns:

        \(conversationText)
        """

        let summaryResponse = try await summarySession.respond(
            to: Prompt(summaryPrompt),
            generating: HealthConversationSummary.self
        )

        return summaryResponse.content
    }

    func respondWithNewSession(to userMessage: String, shouldSaveUserMessage: Bool = true) async throws {
        if shouldSaveUserMessage {
            await saveMessageToSession(userMessage, isFromUser: true)
        }

        let responseStream = session.streamResponse(to: Prompt(userMessage))

        var responseText = ""
        streamingTask?.cancel()
        let task = Task { @MainActor in
            for try await _ in responseStream {
                // The streaming automatically updates the session transcript
            }
        }
        streamingTask = task
        defer { streamingTask = nil }
        do {
            try await task.value
        } catch is CancellationError {
            return
        }

        responseText = latestResponseText()

        if !responseText.isEmpty {
            await saveMessageToSession(responseText, isFromUser: false)
        }
    }
}
