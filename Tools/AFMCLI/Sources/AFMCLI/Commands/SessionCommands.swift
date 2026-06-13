import ArgumentParser
import Foundation
import FoundationLabCore
import FoundationModels

struct SessionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session",
        abstract: "Run one-shot, streaming, or multi-turn session flows.",
        discussion: HelpText.session,
        subcommands: [
            SessionRespondCommand.self,
            SessionStreamCommand.self,
            SessionChatCommand.self
        ]
    )
}

struct SessionResponsePayload: Encodable {
    let command: String
    let adapter: String?
    let useCase: String
    let guardrails: String
    let prompt: String?
    let messages: [String]?
    let response: String?
    let exchanges: [AFMConversationExchange]?
    let sessionCount: Int
    let tokenCount: Int
    let transcript: [CLITranscriptEntry]?
}

private struct SessionStreamingEventPayload: Encodable {
    let event: String
    let command: String
    let adapter: String?
    let useCase: String?
    let guardrails: String?
    let messageIndex: Int?
    let prompt: String?
    let content: String?
    let response: String?
    let exchanges: [AFMConversationExchange]?
    let sessionCount: Int?
    let tokenCount: Int?
    let transcript: [CLITranscriptEntry]?
}

struct SessionRespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "Send one prompt through a fresh session and print the final response."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags
    @OptionGroup var promptInput: PromptInputOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedPrompt = try requiredResolvedInput(promptInput.resolve())
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath()
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "session respond",
                    adapter: adapterPath,
                    prompt: resolvedPrompt.value,
                    promptFile: resolvedPrompt.file,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    toolFiles: toolResolution.references.map { $0.filePath },
                    toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
                ),
                human: "[dry-run] afm session respond\nPrompt: \(resolvedPrompt.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(useCase: useCaseFlags.useCase)
        let engine = try await MainActor.run {
            try makeConversationEngine(
                configuration: defaultConversationConfiguration(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools
                ),
                adapterPath: adapterPath
            )
        }
        let response = try await engine.sendMessage(resolvedPrompt.value, generationOptions: generationOptions)
        let transcript = await MainActor.run {
            transcriptFlags.transcript ? transcriptPayload(engine.session.transcript) : nil
        }
        let sessionCount = await MainActor.run { engine.sessionCount }
        let tokenCount = await MainActor.run { engine.currentTokenCount }

        let payload = SessionResponsePayload(
            command: "session respond",
            adapter: adapterPath,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            prompt: resolvedPrompt.value,
            messages: nil,
            response: response,
            exchanges: nil,
            sessionCount: sessionCount,
            tokenCount: tokenCount,
            transcript: transcript
        )
        let human = humanReadableSessionResponse(
            response: response,
            transcript: transcript,
            sessionCount: sessionCount,
            tokenCount: tokenCount,
            verbose: options.verbose
        )
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct SessionStreamCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream one response from a fresh session as it is generated."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags
    @OptionGroup var promptInput: PromptInputOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedPrompt = try requiredResolvedInput(promptInput.resolve())
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath()
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "session stream",
                    adapter: adapterPath,
                    prompt: resolvedPrompt.value,
                    promptFile: resolvedPrompt.file,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    toolFiles: toolResolution.references.map { $0.filePath },
                    toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
                ),
                human: "[dry-run] afm session stream\nPrompt: \(resolvedPrompt.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(useCase: useCaseFlags.useCase)
        let engine = try await MainActor.run {
            try makeConversationEngine(
                configuration: defaultConversationConfiguration(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools
                ),
                adapterPath: adapterPath
            )
        }

        let streamToConsole = resolvedOutput.format == .text
        let streamToJSON = resolvedOutput.format == .json
        let selectedUseCase = useCaseFlags.useCase.rawValue
        let selectedGuardrails = generation.guardrails.afmArgumentValue
        if streamToJSON && options.pretty {
            throw ValidationError("--pretty is not supported with streaming JSON output")
        }
        var latestPrinted = ""
        if streamToConsole {
            print("Assistant: ", terminator: "")
            fflush(stdout)
        }
        if streamToJSON {
            emitSessionStreamingEvent(
                .init(
                    event: "started",
                    command: "session stream",
                    adapter: adapterPath,
                    useCase: selectedUseCase,
                    guardrails: selectedGuardrails,
                    messageIndex: nil,
                    prompt: resolvedPrompt.value,
                    content: nil,
                    response: nil,
                    exchanges: nil,
                    sessionCount: nil,
                    tokenCount: nil,
                    transcript: nil
                )
            )
        }

        let response = try await engine.sendStreamingMessage(resolvedPrompt.value, generationOptions: generationOptions) { partial in
            if streamToConsole {
                if partial.hasPrefix(latestPrinted) {
                    let suffix = String(partial.dropFirst(latestPrinted.count))
                    guard !suffix.isEmpty else { return }
                    print(suffix, terminator: "")
                } else {
                    print(partial, terminator: "")
                }
                fflush(stdout)
                latestPrinted = partial
                return
            }
            if streamToJSON {
                emitSessionStreamingEvent(
                    .init(
                        event: "delta",
                        command: "session stream",
                        adapter: adapterPath,
                        useCase: selectedUseCase,
                        guardrails: selectedGuardrails,
                        messageIndex: nil,
                        prompt: resolvedPrompt.value,
                        content: partial,
                        response: nil,
                        exchanges: nil,
                        sessionCount: nil,
                        tokenCount: nil,
                        transcript: nil
                    )
                )
            }
        }

        if streamToConsole {
            print("")
        }

        let transcript = await MainActor.run {
            transcriptFlags.transcript ? transcriptPayload(engine.session.transcript) : nil
        }
        let sessionCount = await MainActor.run { engine.sessionCount }
        let tokenCount = await MainActor.run { engine.currentTokenCount }
        let payload = SessionResponsePayload(
            command: "session stream",
            adapter: adapterPath,
            useCase: selectedUseCase,
            guardrails: selectedGuardrails,
            prompt: resolvedPrompt.value,
            messages: nil,
            response: response,
            exchanges: nil,
            sessionCount: sessionCount,
            tokenCount: tokenCount,
            transcript: transcript
        )
        if streamToJSON {
            emitSessionStreamingEvent(
                .init(
                    event: "completed",
                    command: "session stream",
                    adapter: adapterPath,
                    useCase: selectedUseCase,
                    guardrails: selectedGuardrails,
                    messageIndex: nil,
                    prompt: resolvedPrompt.value,
                    content: nil,
                    response: response,
                    exchanges: nil,
                    sessionCount: sessionCount,
                    tokenCount: tokenCount,
                    transcript: transcript
                )
            )
            return
        }
        let human = resolvedOutput.format == .text
            ? humanReadableSessionResponse(
                response: "",
                transcript: transcript,
                sessionCount: sessionCount,
                tokenCount: tokenCount,
                verbose: options.verbose
            )
            : humanReadableSessionResponse(
                response: response,
                transcript: transcript,
                sessionCount: sessionCount,
                tokenCount: tokenCount,
                verbose: options.verbose
            )
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct SessionChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Send multiple prompts through one shared session."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags
    @OptionGroup var session: SessionOptions
    @OptionGroup var streaming: StreamingOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedMessages = try session.resolveMessages()
        let validatedMessages = resolvedMessages.map(\.value)
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath()
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "session chat",
                    adapter: adapterPath,
                    messages: validatedMessages,
                    messageFiles: resolvedMessages.compactMap { $0.file },
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    toolFiles: toolResolution.references.map { $0.filePath },
                    toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
                ),
                human: "[dry-run] afm session chat\nMessages: \(validatedMessages.count)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(useCase: useCaseFlags.useCase)
        let engine = try await MainActor.run {
            try makeConversationEngine(
                configuration: defaultConversationConfiguration(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools
                ),
                adapterPath: adapterPath
            )
        }
        var exchanges: [AFMConversationExchange] = []
        let streamToConsole = streaming.stream && resolvedOutput.format == .text
        let streamToJSON = streaming.stream && resolvedOutput.format == .json
        let selectedUseCase = useCaseFlags.useCase.rawValue
        let selectedGuardrails = generation.guardrails.afmArgumentValue
        if streamToJSON && options.pretty {
            throw ValidationError("--pretty is not supported with streaming JSON output")
        }

        for (index, entry) in validatedMessages.enumerated() {
            if streamToConsole {
                print("User: \(entry)")
                print("Assistant: ", terminator: "")
                fflush(stdout)
            }
            if streamToJSON {
                emitSessionStreamingEvent(
                    .init(
                        event: "message_started",
                        command: "session chat",
                        adapter: adapterPath,
                        useCase: selectedUseCase,
                        guardrails: selectedGuardrails,
                        messageIndex: index,
                        prompt: entry,
                        content: nil,
                        response: nil,
                        exchanges: nil,
                        sessionCount: nil,
                        tokenCount: nil,
                        transcript: nil
                    )
                )
            }

            var latestPrinted = ""
            let response: String
            if streamToConsole || streamToJSON {
                response = try await engine.sendStreamingMessage(entry, generationOptions: generationOptions) { partial in
                    if streamToConsole {
                        if partial.hasPrefix(latestPrinted) {
                            let suffix = String(partial.dropFirst(latestPrinted.count))
                            guard !suffix.isEmpty else { return }
                            print(suffix, terminator: "")
                        } else {
                            print(partial, terminator: "")
                        }
                        fflush(stdout)
                        latestPrinted = partial
                        return
                    }
                    if streamToJSON {
                        emitSessionStreamingEvent(
                            .init(
                                event: "message_delta",
                                command: "session chat",
                                adapter: adapterPath,
                                useCase: selectedUseCase,
                                guardrails: selectedGuardrails,
                                messageIndex: index,
                                prompt: entry,
                                content: partial,
                                response: nil,
                                exchanges: nil,
                                sessionCount: nil,
                                tokenCount: nil,
                                transcript: nil
                            )
                        )
                    }
                }
                if streamToConsole {
                    print("")
                }
            } else {
                response = try await engine.sendMessage(entry, generationOptions: generationOptions)
            }

            exchanges.append(AFMConversationExchange(prompt: entry, response: response, isError: false))
            if streamToJSON {
                emitSessionStreamingEvent(
                    .init(
                        event: "message_completed",
                        command: "session chat",
                        adapter: adapterPath,
                        useCase: selectedUseCase,
                        guardrails: selectedGuardrails,
                        messageIndex: index,
                        prompt: entry,
                        content: nil,
                        response: response,
                        exchanges: nil,
                        sessionCount: nil,
                        tokenCount: nil,
                        transcript: nil
                    )
                )
            }
        }

        let transcript = await MainActor.run {
            transcriptFlags.transcript ? transcriptPayload(engine.session.transcript) : nil
        }
        let sessionCount = await MainActor.run { engine.sessionCount }
        let tokenCount = await MainActor.run { engine.currentTokenCount }
        let payload = SessionResponsePayload(
            command: "session chat",
            adapter: adapterPath,
            useCase: selectedUseCase,
            guardrails: selectedGuardrails,
            prompt: nil,
            messages: validatedMessages,
            response: nil,
            exchanges: exchanges,
            sessionCount: sessionCount,
            tokenCount: tokenCount,
            transcript: transcript
        )
        if streamToJSON {
            emitSessionStreamingEvent(
                .init(
                    event: "session_completed",
                    command: "session chat",
                    adapter: adapterPath,
                    useCase: selectedUseCase,
                    guardrails: selectedGuardrails,
                    messageIndex: nil,
                    prompt: nil,
                    content: nil,
                    response: nil,
                    exchanges: exchanges,
                    sessionCount: sessionCount,
                    tokenCount: tokenCount,
                    transcript: transcript
                )
            )
            return
        }
        let human = humanReadableConversation(
            exchanges: exchanges,
            transcript: transcript,
            sessionCount: sessionCount,
            tokenCount: tokenCount,
            verbose: options.verbose,
            streamed: streamToConsole
        )
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

private func humanReadableSessionResponse(
    response: String,
    transcript: [CLITranscriptEntry]?,
    sessionCount: Int,
    tokenCount: Int,
    verbose: Bool
) -> String {
    var lines: [String] = []
    if !response.isEmpty {
        lines.append(response)
    }
    if let transcript, !transcript.isEmpty {
        if !lines.isEmpty { lines.append("") }
        lines.append("Transcript")
        lines.append(
            transcript.map { "\($0.role.capitalized): \($0.content)" }.joined(separator: "\n\n")
        )
    }
    if verbose {
        if !lines.isEmpty { lines.append("") }
        lines.append("Sessions: \(sessionCount)")
        lines.append("Token count: \(tokenCount)")
    }
    return lines.joined(separator: "\n")
}

private func emitSessionStreamingEvent(_ payload: SessionStreamingEventPayload) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    guard let data = try? encoder.encode(payload),
          let text = String(data: data, encoding: .utf8) else {
        return
    }

    print(text)
    fflush(stdout)
}

private func humanReadableConversation(
    exchanges: [AFMConversationExchange],
    transcript: [CLITranscriptEntry]?,
    sessionCount: Int,
    tokenCount: Int,
    verbose: Bool,
    streamed: Bool
) -> String {
    var lines: [String] = []
    if !streamed {
        for exchange in exchanges {
            lines.append("User: \(exchange.prompt)")
            lines.append("Assistant: \(exchange.response)")
            lines.append("")
        }
        if !lines.isEmpty {
            _ = lines.popLast()
        }
    }
    if let transcript, !transcript.isEmpty {
        if !lines.isEmpty { lines.append("") }
        lines.append("Transcript")
        lines.append(
            transcript.map { "\($0.role.capitalized): \($0.content)" }.joined(separator: "\n\n")
        )
    }
    if verbose {
        if !lines.isEmpty { lines.append("") }
        lines.append("Sessions: \(sessionCount)")
        lines.append("Token count: \(tokenCount)")
    }
    return lines.joined(separator: "\n")
}

struct ResolvedToolSet {
    let references: [ResolvedArtifactReference]
    let tools: [any Tool]
}

func resolveToolManifests(_ toolSource: ToolSourceOptions) throws -> ResolvedToolSet {
    let references = try toolSource.resolveTools()
    if references.isEmpty {
        return ResolvedToolSet(references: [], tools: [])
    }

    let manifests = try AFMArtifactRegistry.loadTools(from: references)
    return ResolvedToolSet(
        references: references,
        tools: manifests.map { $0 as any Tool }
    )
}

func requiredResolvedInput(_ input: ResolvedTextInput?) throws -> ResolvedTextInput {
    guard let input else {
        throw ValidationError("Please provide --prompt, --prompt-file, or stdin.")
    }
    return input
}
