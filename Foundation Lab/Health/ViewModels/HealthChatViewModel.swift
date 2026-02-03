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
    private let sessionTimeoutHours: TimeInterval = AppConfiguration.Health.sessionTimeoutHours
    private let logger = Logger(subsystem: "com.foundationlab.health", category: "HealthChatViewModel")

    // MARK: - Published Properties
    var isLoading: Bool = false
    var isSummarizing: Bool = false
    var sessionCount: Int = 1
    var currentHealthMetrics: [MetricType: Double] = [:]

    // MARK: - Public Properties
    private(set) var session: LanguageModelSession
    private var modelContext: ModelContext?
    private let healthDataManager = HealthDataManager.shared

    // MARK: - Tools
    private let tools: [any Tool] = [
        HealthDataTool(),
        HealthAnalysisTool()
    ]

    // MARK: - Initialization
    init() {
        // Create session with tools and instructions for health data access
        self.session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(Self.baseInstructions)
        )
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Public Methods

    @MainActor
    func sendMessage(_ content: String) async {
        isLoading = true

        do {
            // Save user message to session history
            await saveMessageToSession(content, isFromUser: true)

            // Stream response from current session
            let responseStream = session.streamResponse(to: Prompt(content))

            var responseText = ""
            for try await _ in responseStream {
                // The streaming automatically updates the session transcript
            }

            // Extract the response text from the transcript
            responseText = latestResponseText()

            // Save AI response to session history
            if !responseText.isEmpty {
                await saveMessageToSession(responseText, isFromUser: false)
            }

            // Generate insights if health data was discussed
            if shouldGenerateInsight(from: responseText) {
                await generateHealthInsight(from: responseText)
            }

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Handle context window exceeded by summarizing and creating new session
            await handleContextWindowExceeded(userMessage: content)

        } catch {
            // Handle other errors
            await saveMessageToSession("I apologize, but I encountered an error. Please try again.", isFromUser: false)
        }

        isLoading = false
    }

    @MainActor
    func clearChat() {
        sessionCount = 1
        session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(Self.baseInstructions)
        )
    }

    @MainActor
    func loadInitialHealthData() async {
        // Fetch current health data
        await healthDataManager.fetchTodayHealthData()

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
            if case .response = entry {
                return entry.textContent() ?? ""
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
               existingSession.startDate.timeIntervalSinceNow > -sessionTimeoutHours {
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
        } catch {
            isSummarizing = false
            session = LanguageModelSession(
                tools: tools,
                instructions: Instructions(Self.baseInstructions)
            )
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
        for try await _ in responseStream {
            // The streaming automatically updates the session transcript
        }

        responseText = latestResponseText()

        if !responseText.isEmpty {
            await saveMessageToSession(responseText, isFromUser: false)
        }
    }
}
