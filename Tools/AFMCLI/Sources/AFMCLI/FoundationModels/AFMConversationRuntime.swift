import Foundation
import FoundationModels

@MainActor
final class AFMConversationEngine {
    private(set) var session: LanguageModelSession
    private(set) var sessionCount: Int = 1
    private(set) var currentTokenCount: Int = 0
    private(set) var maxContextSize: Int
    private(set) var isSummarizing = false
    private(set) var isApplyingWindow = false

    private var configuration: AFMConversationConfiguration
    private var model: SystemLanguageModel
    private var activeStreamingTask: Task<String, Error>?

    init(configuration: AFMConversationConfiguration) throws {
        self.configuration = configuration
        self.model = try makeModel(
            useCase: configuration.modelUseCase,
            guardrails: configuration.guardrails,
            adapterPath: configuration.adapterPath
        )
        self.maxContextSize = configuration.defaultMaxContextSize
        self.session = Self.makeSession(
            model: model,
            tools: configuration.tools,
            instructions: configuration.baseInstructions
        )
    }

    func setMaxContextSize(_ value: Int) {
        guard value > 0 else { return }
        maxContextSize = value
    }

    func sendStreamingMessage(
        _ content: String,
        generationOptions: AFMGenerationOptions? = nil,
        onPartialResponse: (@MainActor @Sendable (String) -> Void)? = nil
    ) async throws -> String {
        let prompt = try validatedPrompt(from: content)

        do {
            if await shouldApplyWindow() {
                await applySlidingWindow()
            }

            let response = try await streamResponse(
                to: prompt,
                generationOptions: generationOptions,
                onPartialResponse: onPartialResponse
            )
            await updateTokenCount()
            return response
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            return try await recoverFromContextOverflow(
                userMessage: prompt,
                generationOptions: generationOptions,
                responseMode: .streaming,
                onPartialResponse: onPartialResponse
            )
        }
    }

    func sendMessage(
        _ content: String,
        generationOptions: AFMGenerationOptions? = nil
    ) async throws -> String {
        let prompt = try validatedPrompt(from: content)

        do {
            if await shouldApplyWindow() {
                await applySlidingWindow()
            }

            let response = try await respond(to: prompt, generationOptions: generationOptions)
            await updateTokenCount()
            return response
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            return try await recoverFromContextOverflow(
                userMessage: prompt,
                generationOptions: generationOptions,
                responseMode: .oneShot,
                onPartialResponse: nil
            )
        }
    }
}

private extension AFMConversationEngine {
    enum ResponseMode {
        case streaming
        case oneShot
    }

    func validatedPrompt(from content: String) throws -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AFMRuntimeError.invalidRequest("Missing prompt")
        }
        return trimmed
    }

    func shouldApplyWindow() async -> Bool {
        guard configuration.enableSlidingWindow, configuration.tools.isEmpty else {
            return false
        }

        return await session.transcript.afmIsApproachingLimit(
            threshold: configuration.windowThreshold,
            maxTokens: maxContextSize,
            using: model
        )
    }

    func applySlidingWindow() async {
        guard configuration.enableSlidingWindow, configuration.tools.isEmpty else {
            return
        }

        isApplyingWindow = true
        let windowEntries = await session.transcript.afmEntriesWithinTokenBudget(
            configuration.targetWindowSize,
            using: model
        )
        session = LanguageModelSession(model: model, transcript: Transcript(entries: windowEntries))
        sessionCount += 1
        await updateTokenCount()
        isApplyingWindow = false
    }

    func updateTokenCount() async {
        currentTokenCount = await session.transcript.afmTokenCount(using: model)
    }

    func streamResponse(
        to prompt: String,
        generationOptions: AFMGenerationOptions?,
        onPartialResponse: (@MainActor @Sendable (String) -> Void)?
    ) async throws -> String {
        activeStreamingTask?.cancel()
        let task = Task<String, Error> { @MainActor [weak self] in
            guard let self else { throw CancellationError() }

            var latest = ""
            if let generationOptions {
                for try await snapshot in self.session.streamResponse(
                    to: Prompt(prompt),
                    options: generationOptions.foundationModelsValue
                ) {
                    latest = snapshot.content
                    onPartialResponse?(snapshot.content)
                }
            } else {
                for try await snapshot in self.session.streamResponse(to: Prompt(prompt)) {
                    latest = snapshot.content
                    onPartialResponse?(snapshot.content)
                }
            }

            return latest.isEmpty ? self.latestResponseText() : latest
        }

        activeStreamingTask = task
        defer { activeStreamingTask = nil }
        return try await task.value
    }

    func respond(to prompt: String, generationOptions: AFMGenerationOptions?) async throws -> String {
        if let generationOptions {
            return try await session.respond(
                to: Prompt(prompt),
                options: generationOptions.foundationModelsValue
            ).content
        }

        return try await session.respond(to: Prompt(prompt)).content
    }

    func recoverFromContextOverflow(
        userMessage: String,
        generationOptions: AFMGenerationOptions?,
        responseMode: ResponseMode,
        onPartialResponse: (@MainActor @Sendable (String) -> Void)?
    ) async throws -> String {
        isSummarizing = true
        defer { isSummarizing = false }

        do {
            let summary = try await generateConversationSummary()
            createNewSession(with: summary)
        } catch {
            createFreshSessionAfterOverflow()
            if let overflowResetMessage = trimmedOverflowResetMessage() {
                onPartialResponse?(overflowResetMessage)
                return overflowResetMessage
            }
            throw error
        }

        let response: String
        switch responseMode {
        case .streaming:
            response = try await streamResponse(
                to: userMessage,
                generationOptions: generationOptions,
                onPartialResponse: onPartialResponse
            )
        case .oneShot:
            response = try await respond(to: userMessage, generationOptions: generationOptions)
        }

        await updateTokenCount()
        return response
    }

    func generateConversationSummary() async throws -> AFMConversationSummary {
        let summarySession = LanguageModelSession(
            model: model,
            instructions: Instructions(configuration.summaryInstructions)
        )
        let conversationText = AFMConversationContextBuilder.conversationText(
            from: session.transcript,
            userLabel: configuration.conversationUserLabel,
            assistantLabel: configuration.conversationAssistantLabel
        )
        let summaryPrompt = """
        \(configuration.summaryPromptPreamble)

        \(conversationText)
        """

        return try await summarySession.respond(
            to: Prompt(summaryPrompt),
            generating: AFMConversationSummary.self
        ).content
    }

    func createNewSession(with summary: AFMConversationSummary) {
        let contextInstructions = AFMConversationContextBuilder.contextInstructions(
            baseInstructions: configuration.baseInstructions,
            summary: summary,
            continuationNote: configuration.continuationNote
        )

        session = Self.makeSession(
            model: model,
            tools: configuration.tools,
            instructions: contextInstructions
        )
        sessionCount += 1
        currentTokenCount = 0
    }

    func createFreshSessionAfterOverflow() {
        session = Self.makeSession(
            model: model,
            tools: configuration.tools,
            instructions: configuration.baseInstructions
        )
        sessionCount += 1
        currentTokenCount = 0
    }

    func trimmedOverflowResetMessage() -> String? {
        guard let message = configuration.overflowResetMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else {
            return nil
        }
        return message
    }

    func latestResponseText() -> String {
        for entry in session.transcript.reversed() {
            switch entry {
            case .response:
                return entry.afmTextContent() ?? ""
            case .prompt:
                return ""
            default:
                continue
            }
        }

        return ""
    }

    static func makeSession(
        model: SystemLanguageModel,
        tools: [any Tool],
        instructions: String
    ) -> LanguageModelSession {
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tools.isEmpty {
            if trimmedInstructions.isEmpty {
                return LanguageModelSession(model: model, tools: tools)
            }
            return LanguageModelSession(
                model: model,
                tools: tools,
                instructions: Instructions(trimmedInstructions)
            )
        }

        if trimmedInstructions.isEmpty {
            return LanguageModelSession(model: model)
        }

        return LanguageModelSession(model: model, instructions: Instructions(trimmedInstructions))
    }
}

enum AFMConversationContextBuilder {
    static func conversationText(
        from transcript: Transcript,
        userLabel: String,
        assistantLabel: String
    ) -> String {
        transcript.compactMap { entry in
            switch entry {
            case .prompt:
                guard let text = entry.afmTextContent() else { return nil }
                return "\(userLabel) \(text)"
            case .response:
                guard let text = entry.afmTextContent() else { return nil }
                return "\(assistantLabel) \(text)"
            default:
                return nil
            }
        }.joined(separator: "\n\n")
    }

    static func contextInstructions(
        baseInstructions: String,
        summary: AFMConversationSummary,
        continuationNote: String? = nil
    ) -> String {
        var contextInstructions = """
        \(baseInstructions)

        You are continuing a conversation with a user. Here's a summary of your previous conversation:

        CONVERSATION SUMMARY:
        \(summary.summary)

        KEY TOPICS DISCUSSED:
        \(summary.keyTopics.afmBulletList())

        USER PREFERENCES/REQUESTS:
        \(summary.userPreferences.afmBulletList())
        """

        if let continuationNote, !continuationNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            contextInstructions += "\n\n\(continuationNote)"
        }

        return contextInstructions
    }
}

private extension Array where Element == String {
    func afmBulletList(prefix: String = "• ") -> String {
        guard !isEmpty else { return "\(prefix)None recorded yet" }
        return map { "\(prefix)\($0)" }.joined(separator: "\n")
    }
}
