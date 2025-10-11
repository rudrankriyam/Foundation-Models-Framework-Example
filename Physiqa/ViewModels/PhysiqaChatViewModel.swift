//
//  PhysiqaChatViewModel.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels
import Observation
import SwiftData

@Observable
final class PhysiqaChatViewModel {

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
            instructions: Instructions(
                "You are Physiqa, a friendly and knowledgeable health coach AI assistant. " +
                "Based on the user's health data, provide personalized, encouraging responses. " +
                "Be supportive and celebrate small wins. Use emojis occasionally."
            )
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
            if let lastEntry = session.transcript.last,
               case .response(let response) = lastEntry {
                responseText = response.segments.compactMap { segment in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
            }

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
            instructions: Instructions(
                "You are Physiqa, a friendly and knowledgeable health coach AI assistant. " +
                "Based on the user's health data, provide personalized, encouraging responses. " +
                "Be supportive and celebrate small wins. Use emojis occasionally."
            )
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

    // MARK: - Private Methods

    @MainActor
    private func saveMessageToSession(_ content: String, isFromUser: Bool) async {
        guard let modelContext = modelContext else { return }

        // Check if there's an active session or create a new one
        let descriptor = FetchDescriptor<PhysiqaSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            let activeSession: PhysiqaSession

            if let existingSession = sessions.first,
               existingSession.startDate.timeIntervalSinceNow > -3600 { // Within last hour
                activeSession = existingSession
            } else {
                // Create new session
                activeSession = PhysiqaSession(sessionType: .coaching)
                modelContext.insert(activeSession)
            }

            // Add message to session
            let message = BuddyMessage(content: content, isFromUser: isFromUser)
            activeSession.messages.append(message)

            try modelContext.save()
        } catch {
            // Handle save error silently
        }
    }

    private func shouldGenerateInsight(from response: String) -> Bool {
        let insightKeywords = ["goal", "achieve", "progress", "improve", "recommend", "suggest", "tip", "advice"]
        return insightKeywords.contains { response.lowercased().contains($0) }
    }

    @MainActor
    private func generateHealthInsight(from response: String) async {
        guard let modelContext = modelContext else { return }

        // Create an insight based on the conversation
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
            // Handle save error silently
        }
    }

    @MainActor
    private func handleContextWindowExceeded(userMessage: String) async {
        isSummarizing = true

        do {
            let summary = try await generateConversationSummary()
            createNewSessionWithContext(summary: summary)
            isSummarizing = false

            try await respondWithNewSession(to: userMessage)
        } catch {
            isSummarizing = false
            await saveMessageToSession("I need to start a fresh conversation. Please repeat your question.", isFromUser: false)
        }
    }

    private func createConversationText() -> String {
        return session.transcript.compactMap { entry in
            switch entry {
            case .prompt(let prompt):
                let text = prompt.segments.compactMap { segment in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
                return "User: \(text)"
            case .response(let response):
                let text = response.segments.compactMap { segment in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
                return "Physiqa: \(text)"
            default:
                return nil
            }
        }.joined(separator: "\n\n")
    }

    @MainActor
    private func generateConversationSummary() async throws -> ConversationSummary {
        let summarySession = LanguageModelSession(
            instructions: Instructions(
                "You are an expert at summarizing health coaching conversations. Create comprehensive summaries that preserve all health metrics discussed, goals set, and advice given."
            )
        )

        let conversationText = createConversationText()
        let summaryPrompt = """
        Please summarize the following health coaching conversation. Include all health metrics discussed, goals mentioned, advice given, and user's health concerns:

        \(conversationText)
        """

        let summaryResponse = try await summarySession.respond(
            to: Prompt(summaryPrompt),
            generating: ConversationSummary.self
        )

        return summaryResponse.content
    }

    private func createNewSessionWithContext(summary: ConversationSummary) {
        let contextInstructions = """
        You are Physiqa, a friendly and knowledgeable health coach AI assistant.
        Based on the user's health data, provide personalized, encouraging responses.
        Be supportive and celebrate small wins. Use emojis occasionally.

        You are continuing a conversation with a user. Here's a summary of your previous conversation:

        CONVERSATION SUMMARY:
        \(summary.summary)

        KEY TOPICS DISCUSSED:
        \(summary.keyTopics.map { "• \($0)" }.joined(separator: "\n"))

        USER PREFERENCES/REQUESTS:
        \(summary.userPreferences.map { "• \($0)" }.joined(separator: "\n"))

        Continue the conversation naturally, referencing this context when relevant.
        """

        session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(contextInstructions)
        )
        sessionCount += 1
    }

    @MainActor
    private func respondWithNewSession(to userMessage: String) async throws {
        await saveMessageToSession(userMessage, isFromUser: true)

        let responseStream = session.streamResponse(to: Prompt(userMessage))

        var responseText = ""
        for try await _ in responseStream {
            // The streaming automatically updates the session transcript
        }

        // Extract the response text from the transcript
        if let lastEntry = session.transcript.last,
           case .response(let response) = lastEntry {
            responseText = response.segments.compactMap { segment in
                if case .text(let textSegment) = segment {
                    return textSegment.content
                }
                return nil
            }.joined(separator: " ")
        }

        if !responseText.isEmpty {
            await saveMessageToSession(responseText, isFromUser: false)
        }
    }
}
