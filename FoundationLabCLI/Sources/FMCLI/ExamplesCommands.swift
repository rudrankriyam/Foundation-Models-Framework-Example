import ArgumentParser
import Foundation
import FoundationLabCore

struct ExamplesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "examples",
        abstract: "Run the shared Foundation Lab example demos.",
        subcommands: [
            ListExamplesCommand.self,
            BasicChatExampleCommand.self,
            JournalingExampleCommand.self,
            CreativeWritingExampleCommand.self,
            StructuredDataExampleCommand.self,
            StreamingExampleCommand.self,
            GenerationGuidesExampleCommand.self,
            GenerationOptionsExampleCommand.self,
            ModelAvailabilityExampleCommand.self
        ],
        defaultSubcommand: ListExamplesCommand.self
    )
}

struct ListExamplesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the shared example demos."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        let demos = FoundationLabExampleDemo.allCases.map {
            [
                "id": $0.rawValue,
                "title": $0.title,
                "defaultPrompt": $0.defaultPrompt
            ]
        }

        let human = FoundationLabExampleDemo.allCases
            .map { "\($0.rawValue): \($0.title)" }
            .joined(separator: "\n")

        CLIOutput.emit(
            payload: ["examples": demos],
            human: human,
            json: options.json
        )
    }
}

struct BasicChatExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "basic-chat",
        abstract: "Run the One-shot example using the shared text generation capability."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Prompt to run. Defaults to the app's shared example prompt.")
    var prompt: String?

    @Option(name: .long, help: "Optional system instructions for the example.")
    var systemPrompt: String?

    @Flag(name: .customLong("permissive-guardrails"), help: "Use the permissive content transformation guardrails from the app example.")
    var permissiveGuardrails = false

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .basicChat)
        let resolvedSystemPrompt = resolvedSystemPromptOrDefault(
            systemPrompt,
            demo: .basicChat
        )

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples basic-chat",
                    "prompt": resolvedPrompt,
                    "systemPrompt": resolvedSystemPrompt ?? ""
                ],
                human: """
                [dry-run] fm examples basic-chat
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateTextUseCase().execute(
                TextGenerationRequest(
                    prompt: resolvedPrompt,
                    systemPrompt: resolvedSystemPrompt,
                    guardrails: permissiveGuardrails ? .permissiveContentTransformations : .default,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.content,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableText(
                    title: FoundationLabExampleDemo.basicChat.title,
                    response: result,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct JournalingExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "journaling",
        abstract: "Run the shared journaling example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Journal entry input. Defaults to the app's shared example prompt.")
    var prompt: String?

    @Option(name: .long, help: "Optional system instructions for the example.")
    var systemPrompt: String?

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .journaling)
        let resolvedSystemPrompt = resolvedSystemPromptOrDefault(
            systemPrompt,
            demo: .journaling
        )

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples journaling",
                    "prompt": resolvedPrompt,
                    "systemPrompt": resolvedSystemPrompt ?? ""
                ],
                human: """
                [dry-run] fm examples journaling
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateStructuredDataUseCase<JournalEntrySummary>().execute(
                StructuredGenerationRequest(
                    prompt: resolvedPrompt,
                    systemPrompt: resolvedSystemPrompt,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.output.plainTextSummary,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableStructuredText(
                    title: FoundationLabExampleDemo.journaling.title,
                    content: result.output.plainTextSummary,
                    metadata: result.metadata,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct CreativeWritingExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "creative-writing",
        abstract: "Run the shared creative writing example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Story idea to expand. Defaults to the app's shared example prompt.")
    var prompt: String?

    @Option(name: .long, help: "Optional system instructions for the example.")
    var systemPrompt: String?

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .creativeWriting)
        let resolvedSystemPrompt = resolvedSystemPromptOrDefault(
            systemPrompt,
            demo: .creativeWriting
        )

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples creative-writing",
                    "prompt": resolvedPrompt,
                    "systemPrompt": resolvedSystemPrompt ?? ""
                ],
                human: """
                [dry-run] fm examples creative-writing
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateStructuredDataUseCase<StoryOutline>().execute(
                StructuredGenerationRequest(
                    prompt: resolvedPrompt,
                    systemPrompt: resolvedSystemPrompt,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.output.plainTextSummary,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableStructuredText(
                    title: FoundationLabExampleDemo.creativeWriting.title,
                    content: result.output.plainTextSummary,
                    metadata: result.metadata,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct StructuredDataExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "structured-data",
        abstract: "Run the shared structured data example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Prompt to turn into a book recommendation. Defaults to the app's shared example prompt.")
    var prompt: String?

    @Option(name: .long, help: "Optional system instructions for the shared capability.")
    var systemPrompt: String?

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .structuredData)

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples structured-data",
                    "prompt": resolvedPrompt,
                    "systemPrompt": systemPrompt ?? ""
                ],
                human: """
                [dry-run] fm examples structured-data
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateBookRecommendationUseCase().execute(
                GenerateBookRecommendationRequest(
                    prompt: resolvedPrompt,
                    systemPrompt: systemPrompt,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.recommendation.plainTextSummary,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableStructuredText(
                    title: FoundationLabExampleDemo.structuredData.title,
                    content: result.recommendation.plainTextSummary,
                    metadata: result.metadata,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct StreamingExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "streaming",
        abstract: "Run the shared streaming example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Prompt to stream. Defaults to the app's shared example prompt.")
    var prompt: String?

    @Option(name: .long, help: "Optional system instructions for the example.")
    var systemPrompt: String?

    @Flag(name: .long, help: "Print streamed partial output live before the final response.")
    var stream = true

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .streaming)
        let resolvedSystemPrompt = resolvedSystemPromptOrDefault(
            systemPrompt,
            demo: .streaming
        )

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples streaming",
                    "prompt": resolvedPrompt,
                    "systemPrompt": resolvedSystemPrompt ?? ""
                ],
                human: """
                [dry-run] fm examples streaming
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let shouldStreamToConsole = stream && !options.json

            if shouldStreamToConsole {
                print("Streaming output:")
            }

            let result = try await StreamTextGenerationUseCase().execute(
                StreamingTextGenerationRequest(
                    prompt: resolvedPrompt,
                    systemPrompt: resolvedSystemPrompt,
                    context: cliContext()
                )
            ) { partialResponse in
                guard shouldStreamToConsole else { return }
                print("\u{001B}[2K\r\(partialResponse)", terminator: "")
                fflush(stdout)
            }

            if shouldStreamToConsole {
                print("")
            }

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.content,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableText(
                    title: FoundationLabExampleDemo.streaming.title,
                    response: result,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct GenerationGuidesExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generation-guides",
        abstract: "Run the shared generation guides example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Prompt to turn into a product review. Defaults to the app's shared example prompt.")
    var prompt: String?

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .generationGuides)

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples generation-guides",
                    "prompt": resolvedPrompt
                ],
                human: """
                [dry-run] fm examples generation-guides
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateStructuredDataUseCase<ProductReview>().execute(
                StructuredGenerationRequest(
                    prompt: resolvedPrompt,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.output.plainTextSummary,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableStructuredText(
                    title: FoundationLabExampleDemo.generationGuides.title,
                    content: result.output.plainTextSummary,
                    metadata: result.metadata,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

enum ExampleSamplingMode: String, ExpressibleByArgument, CaseIterable {
    case greedy
    case topK = "top-k"
    case nucleus
}

struct GenerationOptionsExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generation-options",
        abstract: "Run the shared generation options example."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Prompt to generate from. Defaults to the app's shared example prompt.")
    var prompt: String?

    @Option(name: .long, help: "Sampling mode to use.")
    var samplingMode: ExampleSamplingMode = .nucleus

    @Option(name: .customLong("temperature"), help: "Sampling temperature.")
    var temperature = 0.7

    @Option(name: .customLong("top-k"), help: "Top-K value when using top-k sampling.")
    var topK = 50

    @Option(name: .customLong("top-p"), help: "Probability threshold when using nucleus sampling.")
    var topP = 0.9

    @Option(name: .customLong("max-tokens"), help: "Maximum response tokens.")
    var maximumResponseTokens = 500

    mutating func run() async throws {
        let resolvedPrompt = try resolvedExamplePrompt(prompt, demo: .generationOptions)

        let sampling: FoundationLabGenerationOptions.SamplingMode? = switch samplingMode {
        case .greedy:
            .greedy
        case .topK:
            .randomTop(topK)
        case .nucleus:
            .randomProbabilityThreshold(topP)
        }

        let generationOptions = FoundationLabGenerationOptions(
            sampling: sampling,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "examples generation-options",
                    "prompt": resolvedPrompt,
                    "temperature": temperature,
                    "maximumResponseTokens": maximumResponseTokens
                ],
                human: """
                [dry-run] fm examples generation-options
                Prompt: \(resolvedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireFoundationModelsAvailability()

            let result = try await GenerateTextUseCase().execute(
                TextGenerationRequest(
                    prompt: resolvedPrompt,
                    generationOptions: generationOptions,
                    context: cliContext()
                )
            )

            CLIOutput.emit(
                payload: [
                    "prompt": resolvedPrompt,
                    "content": result.content,
                    "samplingMode": samplingMode.rawValue,
                    "temperature": temperature,
                    "maximumResponseTokens": maximumResponseTokens,
                    "metadata": metadataPayload(result.metadata)
                ],
                human: humanReadableText(
                    title: FoundationLabExampleDemo.generationOptions.title,
                    response: result,
                    verbose: options.verbose
                ),
                json: options.json
            )
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct ModelAvailabilityExampleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model-availability",
        abstract: "Run the shared model availability example."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        let result = CheckModelAvailabilityUseCase().execute()

        CLIOutput.emit(
            payload: [
                "isAvailable": result.isAvailable,
                "reason": result.reason?.rawValue ?? ""
            ],
            human: humanReadableAvailabilityOutput(result),
            json: options.json
        )
    }
}

private func resolvedExamplePrompt(
    _ prompt: String?,
    demo: FoundationLabExampleDemo
) throws -> String {
    let resolvedPrompt = prompt ?? demo.defaultPrompt
    return try validatedNonEmpty(resolvedPrompt, optionName: "--prompt")
}

private func resolvedSystemPromptOrDefault(
    _ systemPrompt: String?,
    demo: FoundationLabExampleDemo
) -> String? {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        return trimmedSystemPrompt
    }
    return demo.defaultSystemPrompt
}

private func humanReadableStructuredText(
    title: String,
    content: String,
    metadata: CapabilityExecutionMetadata,
    verbose: Bool
) -> String {
    var lines = [title, "", content]

    if verbose {
        let provider = metadata.provider ?? "Unknown"
        let tokenCount = metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("")
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}

private func humanReadableAvailabilityOutput(_ result: ModelAvailabilityResult) -> String {
    guard !result.isAvailable else {
        return "Apple Intelligence is available and ready to use."
    }

    switch result.reason {
    case .deviceNotEligible:
        return "Apple Intelligence is unavailable because this device is not eligible."
    case .appleIntelligenceNotEnabled:
        return "Apple Intelligence is unavailable because it is not enabled in Settings."
    case .modelNotReady:
        return "Apple Intelligence is still preparing model assets on this device."
    case .unknown, .none:
        return "Apple Intelligence is unavailable on this device right now."
    }
}
