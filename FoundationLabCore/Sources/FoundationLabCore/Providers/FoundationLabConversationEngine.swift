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
    public var modelRuntime: FoundationLabModelRuntime {
        configuration.modelRuntime
    }
    public var reasoningLevel: FoundationLabReasoningLevel {
        configuration.reasoningLevel
    }

    private var configuration: FoundationLabConversationConfiguration
    private var model: SystemLanguageModel
    private var activeStreamingTask: Task<String, Error>?

    public init(configuration: FoundationLabConversationConfiguration) {
        self.configuration = configuration
        self.model = SystemLanguageModel(
            useCase: configuration.modelUseCase.foundationModelsValue,
            guardrails: configuration.guardrails.foundationModelsValue
        )
        self.maxContextSize = configuration.defaultMaxContextSize
        self.session = Self.makeSession(
            runtime: configuration.modelRuntime,
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
        modelRuntime: FoundationLabModelRuntime? = nil,
        reasoningLevel: FoundationLabReasoningLevel? = nil,
        guardrails: FoundationLabGuardrails? = nil
    ) {
        if let baseInstructions {
            configuration.baseInstructions = baseInstructions
        }
        if let modelRuntime {
            configuration.modelRuntime = modelRuntime
        }
        if let reasoningLevel {
            configuration.reasoningLevel = reasoningLevel
        }
        if let guardrails {
            configuration.guardrails = guardrails
        }

        model = SystemLanguageModel(
            useCase: configuration.modelUseCase.foundationModelsValue,
            guardrails: configuration.guardrails.foundationModelsValue
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

    public func prewarm(withPromptPrefix promptPrefix: String?) {
        let trimmedPrefix = promptPrefix?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedPrefix, !trimmedPrefix.isEmpty {
            session.prewarm(promptPrefix: Prompt(trimmedPrefix))
        } else {
            session.prewarm()
        }
    }

    public func sendStreamingMessage(
        _ content: String,
        generationOptions: FoundationLabGenerationOptions? = nil,
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

    public func sendMessage(
        _ content: String,
        generationOptions: FoundationLabGenerationOptions? = nil
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
            runtime: configuration.modelRuntime,
            model: model,
            tools: configuration.tools,
            instructions: configuration.baseInstructions
        )
        notifyStateChange()
    }

    func shouldApplyWindow() async -> Bool {
        guard configuration.enableSlidingWindow, configuration.tools.isEmpty, configuration.modelRuntime == .onDevice else {
            return false
        }

        return await session.transcript.foundationLabIsApproachingLimit(
            threshold: configuration.windowThreshold,
            maxTokens: maxContextSize,
            using: model
        )
    }

    func applySlidingWindow() async {
        guard configuration.enableSlidingWindow, configuration.tools.isEmpty, configuration.modelRuntime == .onDevice else {
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
        switch configuration.modelRuntime {
        case .onDevice:
            currentTokenCount = await session.transcript.foundationLabTokenCount(using: model)
        case .privateCloudCompute:
            currentTokenCount = session.transcript.foundationLabEstimatedTokenCount
        }
        notifyStateChange()
    }

    func streamResponse(
        to prompt: String,
        generationOptions: FoundationLabGenerationOptions?,
        onPartialResponse: (@MainActor @Sendable (String) -> Void)?
    ) async throws -> String {
        activeStreamingTask?.cancel()
        let task = Task<String, Error> { @MainActor [weak self] in
            guard let self else {
                throw CancellationError()
            }

            var latest = ""
            if let generationOptions {
                #if compiler(>=6.4)
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                    if let contextOptions = self.contextOptions() {
                        for try await snapshot in self.session.streamResponse(
                            to: Prompt(prompt),
                            options: generationOptions.foundationModelsValue,
                            contextOptions: contextOptions
                        ) {
                            latest = snapshot.content
                            onPartialResponse?(snapshot.content)
                        }
                    } else {
                        for try await snapshot in self.session.streamResponse(
                            to: Prompt(prompt),
                            options: generationOptions.foundationModelsValue
                        ) {
                            latest = snapshot.content
                            onPartialResponse?(snapshot.content)
                        }
                    }
                    return latest.isEmpty ? self.latestResponseText() : latest
                }
                #endif

                for try await snapshot in self.session.streamResponse(
                    to: Prompt(prompt),
                    options: generationOptions.foundationModelsValue
                ) {
                    latest = snapshot.content
                    onPartialResponse?(snapshot.content)
                }
            } else {
                #if compiler(>=6.4)
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                    if let contextOptions = self.contextOptions() {
                        for try await snapshot in self.session.streamResponse(
                            to: Prompt(prompt),
                            contextOptions: contextOptions
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
                #endif

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

    func respond(
        to prompt: String,
        generationOptions: FoundationLabGenerationOptions?
    ) async throws -> String {
        if let generationOptions {
            #if compiler(>=6.4)
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                if let contextOptions = contextOptions() {
                    return try await session.respond(
                        to: Prompt(prompt),
                        options: generationOptions.foundationModelsValue,
                        contextOptions: contextOptions
                    ).content
                }

                return try await session.respond(
                    to: Prompt(prompt),
                    options: generationOptions.foundationModelsValue
                ).content
            }
            #endif

            return try await session.respond(
                to: Prompt(prompt),
                options: generationOptions.foundationModelsValue
            ).content
        }

        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            if let contextOptions = contextOptions() {
                return try await session.respond(
                    to: Prompt(prompt),
                    contextOptions: contextOptions
                ).content
            }

            return try await session.respond(
                to: Prompt(prompt)
            ).content
        }
        #endif

        return try await session.respond(to: Prompt(prompt)).content
    }

    func recoverFromContextOverflow(
        userMessage: String,
        generationOptions: FoundationLabGenerationOptions?,
        responseMode: ResponseMode,
        onPartialResponse: (@MainActor @Sendable (String) -> Void)?
    ) async throws -> String {
        isSummarizing = true
        notifyStateChange()

        defer {
            isSummarizing = false
            notifyStateChange()
        }

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

    func generateConversationSummary() async throws -> FoundationLabConversationSummary {
        let summarySession = Self.makeSession(
            runtime: .onDevice,
            model: model,
            tools: [],
            instructions: configuration.summaryInstructions
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
            runtime: configuration.modelRuntime,
            model: model,
            tools: configuration.tools,
            instructions: contextInstructions
        )
        sessionCount += 1
        currentTokenCount = 0
        notifyStateChange()
    }

    func createFreshSessionAfterOverflow() {
        session = Self.makeSession(
            runtime: configuration.modelRuntime,
            model: model,
            tools: configuration.tools,
            instructions: configuration.baseInstructions
        )
        sessionCount += 1
        currentTokenCount = 0
        notifyStateChange()
    }

    func trimmedOverflowResetMessage() -> String? {
        guard let message = configuration.overflowResetMessage?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty else {
            return nil
        }

        return message
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
        makeSession(
            runtime: .onDevice,
            model: model,
            tools: tools,
            instructions: instructions
        )
    }

    static func makeSession(
        runtime: FoundationLabModelRuntime,
        model: SystemLanguageModel,
        tools: [any Tool],
        instructions: String
    ) -> LanguageModelSession {
        #if compiler(>=6.4)
        if runtime == .privateCloudCompute {
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                return makeSession(
                    model: PrivateCloudComputeLanguageModel(),
                    tools: tools,
                    instructions: instructions
                )
            }
        }
        #endif

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

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func makeSession(
        model: PrivateCloudComputeLanguageModel,
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
    #endif

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    func contextOptions() -> ContextOptions? {
        guard configuration.modelRuntime == .privateCloudCompute,
              configuration.reasoningLevel != .none else {
            return nil
        }

        return ContextOptions(reasoningLevel: configuration.reasoningLevel.foundationModelsValue)
    }
    #endif

    func notifyStateChange() {
        onStateChange?()
    }
}
