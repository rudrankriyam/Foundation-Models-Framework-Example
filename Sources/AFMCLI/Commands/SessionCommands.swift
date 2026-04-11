import ArgumentParser
import Foundation
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
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags

    @Option(name: .long, help: "Prompt to send through the session.")
    var prompt: String

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "session respond", prompt: trimmedPrompt),
                human: "[dry-run] afm session respond\nPrompt: \(trimmedPrompt)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability()
        let engine = await MainActor.run {
            AFMConversationEngine(configuration: defaultConversationConfiguration(systemPrompt: generation.systemPrompt))
        }
        let response = try await engine.sendMessage(trimmedPrompt, generationOptions: generationOptions)
        let transcript = await MainActor.run {
            transcriptFlags.transcript ? transcriptPayload(engine.session.transcript) : nil
        }
        let sessionCount = await MainActor.run { engine.sessionCount }
        let tokenCount = await MainActor.run { engine.currentTokenCount }

        let payload = SessionResponsePayload(
            command: "session respond",
            prompt: trimmedPrompt,
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
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags

    @Option(name: .long, help: "Prompt to send through the session.")
    var prompt: String

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "session stream", prompt: trimmedPrompt),
                human: "[dry-run] afm session stream\nPrompt: \(trimmedPrompt)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability()
        let engine = await MainActor.run {
            AFMConversationEngine(configuration: defaultConversationConfiguration(systemPrompt: generation.systemPrompt))
        }

        let streamToConsole = resolvedOutput.format == .text
        let streamToJSON = resolvedOutput.format == .json
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
                    messageIndex: nil,
                    prompt: trimmedPrompt,
                    content: nil,
                    response: nil,
                    exchanges: nil,
                    sessionCount: nil,
                    tokenCount: nil,
                    transcript: nil
                )
            )
        }

        let response = try await engine.sendStreamingMessage(trimmedPrompt, generationOptions: generationOptions) { partial in
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
                        messageIndex: nil,
                        prompt: trimmedPrompt,
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
            prompt: trimmedPrompt,
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
                    messageIndex: nil,
                    prompt: trimmedPrompt,
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
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags

    @Option(name: .long, parsing: .upToNextOption, help: "Message(s) to send through one shared session. Repeat for multi-turn chat.")
    var message: [String] = []

    @Flag(name: .long, help: "Stream each assistant response while it is generated.")
    var stream = false

    mutating func run() async throws {
        let validatedMessages = try validatedNonEmptyValues(message, optionName: "--message")
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "session chat", messages: validatedMessages),
                human: "[dry-run] afm session chat\nMessages: \(validatedMessages.count)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability()
        let engine = await MainActor.run {
            AFMConversationEngine(configuration: defaultConversationConfiguration(systemPrompt: generation.systemPrompt))
        }
        var exchanges: [AFMConversationExchange] = []
        let streamToConsole = stream && resolvedOutput.format == .text
        let streamToJSON = stream && resolvedOutput.format == .json
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
