import ArgumentParser
import Foundation
import FoundationLabCore

struct RunChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run one or more messages through the shared conversation engine."
    )

    @OptionGroup var options: CLIOptions

    @Option(
        name: [.short, .long],
        parsing: .upToNextOption,
        help: "Message(s) to send through one shared session. Repeat the option for multi-turn chat."
    )
    var message: [String] = []

    @Option(name: .long, help: "Optional system instructions for the shared conversation engine.")
    var systemPrompt: String?

    @Flag(name: .long, help: "Stream each assistant response while it is generated.")
    var stream = false

    mutating func run() async throws {
        let validatedMessages = try validatedNonEmptyValues(message, optionName: "--message")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "chat run",
                    "messages": validatedMessages,
                    "systemPrompt": systemPrompt ?? "",
                    "stream": stream
                ],
                human: """
                [dry-run] fm chat run
                Messages: \(validatedMessages.count)
                Stream: \(stream ? "yes" : "no")
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let engine = await MainActor.run {
                FoundationLabConversationEngine(
                    configuration: cliConversationConfiguration(systemPrompt: systemPrompt)
                )
            }

            var exchanges: [[String: String]] = []

            for entry in validatedMessages {
                let response: String

                if stream && !options.json {
                    print("User: \(entry)")
                    print("Assistant: ", terminator: "")
                    fflush(stdout)

                    var latestPrinted = ""
                    response = try await engine.sendStreamingMessage(
                        entry,
                        onPartialResponse: { partialResponse in
                            guard partialResponse.hasPrefix(latestPrinted) else {
                                let suffix = partialResponse
                                print(suffix, terminator: "")
                                fflush(stdout)
                                latestPrinted = partialResponse
                                return
                            }

                            let suffix = String(partialResponse.dropFirst(latestPrinted.count))
                            guard !suffix.isEmpty else { return }
                            print(suffix, terminator: "")
                            fflush(stdout)
                            latestPrinted = partialResponse
                        }
                    )
                    print("\n")
                } else {
                    response = try await engine.sendMessage(entry)
                }

                exchanges.append([
                    "message": entry,
                    "response": response
                ])
            }

            let payload: [String: Any] = [
                "exchanges": exchanges,
                "sessionCount": await MainActor.run { engine.sessionCount },
                "tokenCount": await MainActor.run { engine.currentTokenCount }
            ]

            CLIOutput.emit(
                payload: payload,
                human: humanReadableConversationOutput(
                    exchanges: exchanges,
                    sessionCount: await MainActor.run { engine.sessionCount },
                    tokenCount: await MainActor.run { engine.currentTokenCount },
                    verbose: options.verbose,
                    streamed: stream && !options.json
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}
