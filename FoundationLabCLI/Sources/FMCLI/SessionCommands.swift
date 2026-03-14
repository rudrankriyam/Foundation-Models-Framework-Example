import ArgumentParser
import Foundation
import FoundationLabCore

struct SessionRespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "Send one prompt through a fresh session and print the final response."
    )

    @OptionGroup var options: CLIOptions
    @OptionGroup var generation: CLIGenerationParameters
    @OptionGroup var output: CLISessionOutputOptions

    @Option(name: [.short, .long], help: "Prompt to send through the session.")
    var prompt: String

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")
        let generationOptions = generation.foundationLabValue()

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "session respond",
                    "prompt": trimmedPrompt,
                    "generation": sessionGenerationPayload(generation),
                    "transcript": output.includeTranscript,
                    "feedback": output.feedback?.rawValue ?? ""
                ],
                human: """
                [dry-run] fm session respond
                Prompt: \(trimmedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let engine = await makeConversationEngine(systemPrompt: generation.systemPrompt)
            let response = try await engine.sendMessage(
                trimmedPrompt,
                generationOptions: generationOptions
            )
            let feedback = await logSessionFeedback(output.feedback, on: engine)
            let metrics = await sessionMetrics(from: engine)
            let transcript = await sessionTranscriptSnapshot(
                from: engine,
                includeTranscript: output.includeTranscript
            )

            CLIOutput.emit(
                payload: [
                    "command": "session respond",
                    "prompt": trimmedPrompt,
                    "response": response,
                    "sessionCount": metrics.sessionCount,
                    "tokenCount": metrics.tokenCount,
                    "feedback": feedback ?? "",
                    "transcript": transcript.payload as Any
                ],
                human: humanReadableSessionResponse(
                    response: response,
                    transcriptText: transcript.text,
                    sessionCount: metrics.sessionCount,
                    tokenCount: metrics.tokenCount,
                    feedback: feedback,
                    verbose: options.verbose,
                    streamed: false
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SessionStreamCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream one response from a fresh session as it is generated."
    )

    @OptionGroup var options: CLIOptions
    @OptionGroup var generation: CLIGenerationParameters
    @OptionGroup var output: CLISessionOutputOptions

    @Option(name: [.short, .long], help: "Prompt to send through the session.")
    var prompt: String

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")
        let generationOptions = generation.foundationLabValue()

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "session stream",
                    "prompt": trimmedPrompt,
                    "generation": sessionGenerationPayload(generation),
                    "transcript": output.includeTranscript,
                    "feedback": output.feedback?.rawValue ?? ""
                ],
                human: """
                [dry-run] fm session stream
                Prompt: \(trimmedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let engine = await makeConversationEngine(systemPrompt: generation.systemPrompt)
            let shouldStreamToConsole = !options.json

            if shouldStreamToConsole {
                print("Assistant: ", terminator: "")
                fflush(stdout)
            }

            var latestPrinted = ""
            let response = try await engine.sendStreamingMessage(
                trimmedPrompt,
                generationOptions: generationOptions
            ) { partialResponse in
                guard shouldStreamToConsole else { return }

                if partialResponse.hasPrefix(latestPrinted) {
                    let suffix = String(partialResponse.dropFirst(latestPrinted.count))
                    guard !suffix.isEmpty else { return }
                    print(suffix, terminator: "")
                } else {
                    print(partialResponse, terminator: "")
                }

                fflush(stdout)
                latestPrinted = partialResponse
            }

            if shouldStreamToConsole {
                print("")
            }

            let feedback = await logSessionFeedback(output.feedback, on: engine)
            let metrics = await sessionMetrics(from: engine)
            let transcript = await sessionTranscriptSnapshot(
                from: engine,
                includeTranscript: output.includeTranscript
            )

            CLIOutput.emit(
                payload: [
                    "command": "session stream",
                    "prompt": trimmedPrompt,
                    "response": response,
                    "sessionCount": metrics.sessionCount,
                    "tokenCount": metrics.tokenCount,
                    "feedback": feedback ?? "",
                    "transcript": transcript.payload as Any
                ],
                human: humanReadableSessionResponse(
                    response: response,
                    transcriptText: transcript.text,
                    sessionCount: metrics.sessionCount,
                    tokenCount: metrics.tokenCount,
                    feedback: feedback,
                    verbose: options.verbose,
                    streamed: shouldStreamToConsole
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SessionChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Send multiple prompts through one shared session."
    )

    @OptionGroup var options: CLIOptions
    @OptionGroup var generation: CLIGenerationParameters
    @OptionGroup var output: CLISessionOutputOptions

    @Option(
        name: [.short, .long],
        parsing: .upToNextOption,
        help: "Message(s) to send through one shared session. Repeat the option for multi-turn chat."
    )
    var message: [String] = []

    @Flag(name: .long, help: "Stream each assistant response while it is generated.")
    var stream = false

    mutating func run() async throws {
        let validatedMessages = try validatedNonEmptyValues(message, optionName: "--message")
        let generationOptions = generation.foundationLabValue()

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "session chat",
                    "messages": validatedMessages,
                    "generation": sessionGenerationPayload(generation),
                    "stream": stream,
                    "transcript": output.includeTranscript,
                    "feedback": output.feedback?.rawValue ?? ""
                ],
                human: """
                [dry-run] fm session chat
                Messages: \(validatedMessages.count)
                Stream: \(stream ? "yes" : "no")
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let engine = await makeConversationEngine(systemPrompt: generation.systemPrompt)
            var exchanges: [[String: String]] = []
            let shouldStreamToConsole = stream && !options.json

            for entry in validatedMessages {
                let response: String

                if shouldStreamToConsole {
                    print("User: \(entry)")
                    print("Assistant: ", terminator: "")
                    fflush(stdout)

                    var latestPrinted = ""
                    response = try await engine.sendStreamingMessage(
                        entry,
                        generationOptions: generationOptions
                    ) { partialResponse in
                        if partialResponse.hasPrefix(latestPrinted) {
                            let suffix = String(partialResponse.dropFirst(latestPrinted.count))
                            guard !suffix.isEmpty else { return }
                            print(suffix, terminator: "")
                        } else {
                            print(partialResponse, terminator: "")
                        }

                        fflush(stdout)
                        latestPrinted = partialResponse
                    }
                    print("\n")
                } else {
                    response = try await engine.sendMessage(
                        entry,
                        generationOptions: generationOptions
                    )
                }

                _ = await logSessionFeedback(output.feedback, on: engine)
                exchanges.append([
                    "message": entry,
                    "response": response
                ])
            }

            let metrics = await sessionMetrics(from: engine)
            let transcript = await sessionTranscriptSnapshot(
                from: engine,
                includeTranscript: output.includeTranscript
            )
            let feedback = output.feedback?.rawValue

            CLIOutput.emit(
                payload: [
                    "command": "session chat",
                    "exchanges": exchanges,
                    "sessionCount": metrics.sessionCount,
                    "tokenCount": metrics.tokenCount,
                    "feedback": feedback ?? "",
                    "transcript": transcript.payload as Any
                ],
                human: humanReadableSessionConversation(
                    exchanges: exchanges,
                    transcriptText: transcript.text,
                    sessionCount: metrics.sessionCount,
                    tokenCount: metrics.tokenCount,
                    feedback: feedback,
                    verbose: options.verbose,
                    streamed: shouldStreamToConsole
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}
