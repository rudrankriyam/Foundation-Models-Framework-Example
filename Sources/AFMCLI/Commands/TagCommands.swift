import ArgumentParser
import Foundation

struct TagCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tag",
        abstract: "Try the content tagging system model.",
        subcommands: [
            TagRunCommand.self
        ]
    )
}

struct TagRunPayload: Encodable {
    let command: String
    let prompt: String
    let useCase: String
    let guardrails: String
    let response: String
    let tags: [String]
    let tokenCount: Int?
}

struct TagRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Generate categorizing tags from one prompt."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var promptInput: PromptInputOptions

    mutating func run() async throws {
        let resolvedPrompt = try requiredResolvedInput(promptInput.resolve())
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "tag run",
                    prompt: resolvedPrompt.value,
                    promptFile: resolvedPrompt.file,
                    useCase: AFMModelUseCase.contentTagging.rawValue,
                    guardrails: generation.guardrails.rawValue
                ),
                human: "[dry-run] afm tag run\nPrompt: \(resolvedPrompt.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(useCase: .contentTagging)
        let result = try await GenerateTextUseCase().execute(
            AFMTextGenerationRequest(
                prompt: resolvedPrompt.value,
                systemPrompt: generation.systemPrompt,
                modelUseCase: .contentTagging,
                guardrails: generation.guardrails,
                generationOptions: generationOptions,
                context: afmContext()
            )
        )

        let tags = extractTags(from: result.content)
        let payload = TagRunPayload(
            command: "tag run",
            prompt: resolvedPrompt.value,
            useCase: AFMModelUseCase.contentTagging.rawValue,
            guardrails: generation.guardrails.rawValue,
            response: result.content,
            tags: tags,
            tokenCount: result.metadata.tokenCount
        )

        var lines = ["Tags"]
        if tags.isEmpty {
            lines.append(result.content)
        } else {
            lines.append(tags.joined(separator: "\n"))
        }
        if options.verbose, let tokenCount = result.metadata.tokenCount {
            lines.append("")
            lines.append("Token count: \(tokenCount)")
        }

        try CLIOutput.emit(payload: payload, human: lines.joined(separator: "\n"), options: resolvedOutput)
    }
}

private func extractTags(from response: String) -> [String] {
    let separators = CharacterSet(charactersIn: ",\n")
    return response
        .components(separatedBy: separators)
        .map { fragment in
            fragment
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-*#"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }
}
