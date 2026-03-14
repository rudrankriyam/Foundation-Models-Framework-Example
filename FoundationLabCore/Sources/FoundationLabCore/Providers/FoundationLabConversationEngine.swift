import Foundation
import FoundationModels

@MainActor
public final class FoundationLabConversationEngine {
    public var onStateChange: (@MainActor () -> Void)?

    public private(set) var session: LanguageModelSession
    public private(set) var sessionCount: Int = 1
    public private(set) var currentTokenCount: Int = 0
    public private(set) var maxContextSize: Int
    public private(set) var isSummarizing: Bool = false
    public private(set) var isApplyingWindow: Bool = false

    private var configuration: FoundationLabConversationConfiguration
    private var model: SystemLanguageModel
    private var activeStreamingTask: Task<String, Error>?

    public init(configuration: FoundationLabConversationConfiguration) {
        self.configuration = configuration
        self.model = SystemLanguageModel(
            useCase: configuration.modelUseCase,
            guardrails: configuration.guardrails
        )
        self.maxContextSize = configuration.defaultMaxContextSize
        self.session = Self.makeSession(
            model: model,
            tools: configuration.tools,
            instructions: configuration.baseInstructions
        )
    }

    public func setMaxContextSize(_ value: Int) {
        guard value > 0 else { return }
        maxContextSize = value
        notifyStateChange()
    }

    public func rebuild(
        baseInstructions: String? = nil,
        guardrails: SystemLanguageModel.Guardrails? = nil
    ) {
        if let baseInstructions {
            configuration.baseInstructions = baseInstructions
        }
        if let guardrails {
            configuration.guardrails = guardrails
        }

        model = SystemLanguageModel(
            useCase: configuration.modelUseCase,
            guardrails: configuration.guardrails
        )
        resetSession()
    }

    public func clear() {
        resetSession()
    }

    public func cancelActiveResponse() {
        activeStreamingTask?.cancel()
        activeStreamingTask = nil
    }

    public func prewarm(promptPrefix: Prompt? = nil) {
        if let promptPrefix {
            session.prewarm(promptPrefix: promptPrefix)
        } else {
            session.prewarm()
        }
    }

    public func sendStreamingMessage(
        _ content: String,
        generationOptions: GenerationOptions? = nil
    ) async throws -> String {
        let prompt = try validatedPrompt(from: content)

        do {
            if await shouldApplyWindow() {
                await applySlidingWindow()
            }

            let response = try await streamResponse(to: prompt, generationOptions: generationOptions)
            await updateTokenCount()
            return response
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            return try await recoverFromContextOverflow(
                userMessage: prompt,
                generationOptions: generationOptions,
                responseMode: .streaming
            )
        }
    }

    public func sendMessage(
        _ content: String,
        generationOptions: GenerationOptions? = nil
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
                responseMode: .oneShot
            )
        }
    }
}

private extension FoundationLabConversationEngine {
    enum ResponseMode {
        case streaming
        case oneShot
    }

    func validatedPrompt(from content: String) throws -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }
        return trimmed
    }

    func resetSession() {
        cancelActiveResponse()
        sessionCount = 1
        currentTokenCount = 0
        isSummarizing = false
        isApplyingWindow = false
        session = Self.makeSession(
            model: model,
            tools: configuration.tools,
            instructions: configuration.baseInstructions
        )
        notifyStateChange()
    }

    func shouldApplyWindow() async -> Bool {
        guard configuration.enableSlidingWindow, configuration.tools.isEmpty else {
            return false
        }

        return await session.transcript.foundationLabIsApproachingLimit(
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
        notifyStateChange()

        let windowEntries = await session.transcript.foundationLabEntriesWithinTokenBudget(
            configuration.targetWindowSize,
            using: model
        )
        let transcript = Transcript(entries: windowEntries)

        session = LanguageModelSession(model: model, transcript: transcript)
        sessionCount += 1
        await updateTokenCount()

        isApplyingWindow = false
        notifyStateChange()
    }

    func updateTokenCount() async {
        currentTokenCount = await session.transcript.foundationLabTokenCount(using: model)
        notifyStateChange()
    }

    func streamResponse(
        to prompt: String,
        generationOptions: GenerationOptions?
    ) async throws -> String {
        activeStreamingTask?.cancel()
        let task = Task<String, Error> { @MainActor [weak self] in
            guard let self else {
                throw CancellationError()
            }

            var latest = ""
            if let generationOptions {
                for try await snapshot in self.session.streamResponse(
                    to: Prompt(prompt),
                    options: generationOptions
                ) {
                    latest = snapshot.content
                }
            } else {
                for try await snapshot in self.session.streamResponse(to: Prompt(prompt)) {
                    latest = snapshot.content
                }
            }
            return latest.isEmpty ? self.latestResponseText() : latest
        }

        activeStreamingTask = task
        defer { activeStreamingTask = nil }
        return try await task.value
    }

    func respond(
        to prompt: String,
        generationOptions: GenerationOptions?
    ) async throws -> String {
        if let generationOptions {
            return try await session.respond(
                to: Prompt(prompt),
                options: generationOptions
            ).content
        }

        return try await session.respond(to: Prompt(prompt)).content
    }

    func recoverFromContextOverflow(
        userMessage: String,
        generationOptions: GenerationOptions?,
        responseMode: ResponseMode
    ) async throws -> String {
        isSummarizing = true
        notifyStateChange()

        defer {
            isSummarizing = false
            notifyStateChange()
        }

        let summary = try await generateConversationSummary()
        createNewSession(with: summary)

        let response: String
        switch responseMode {
        case .streaming:
            response = try await streamResponse(to: userMessage, generationOptions: generationOptions)
        case .oneShot:
            response = try await respond(to: userMessage, generationOptions: generationOptions)
        }

        await updateTokenCount()
        return response
    }

    func generateConversationSummary() async throws -> FoundationLabConversationSummary {
        let summarySession = LanguageModelSession(
            model: model,
            instructions: Instructions(configuration.summaryInstructions)
        )

        let conversationText = FoundationLabConversationContextBuilder.conversationText(
            from: session.transcript,
            userLabel: configuration.conversationUserLabel,
            assistantLabel: configuration.conversationAssistantLabel
        )
        let summaryPrompt = """
        \(configuration.summaryPromptPreamble)

        \(conversationText)
        """

        let summaryResponse = try await summarySession.respond(
            to: Prompt(summaryPrompt),
            generating: FoundationLabConversationSummary.self
        )

        return summaryResponse.content
    }

    func createNewSession(with summary: FoundationLabConversationSummary) {
        let contextInstructions = FoundationLabConversationContextBuilder.contextInstructions(
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
        notifyStateChange()
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

        return LanguageModelSession(
            model: model,
            instructions: Instructions(trimmedInstructions)
        )
    }

    func notifyStateChange() {
        onStateChange?()
    }
}
