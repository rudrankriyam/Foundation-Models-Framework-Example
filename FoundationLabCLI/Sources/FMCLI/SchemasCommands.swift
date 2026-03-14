import ArgumentParser
import Foundation
import FoundationLabCore

struct SchemasCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schemas",
        abstract: "Run the shared Foundation Lab schema demos.",
        subcommands: [
            ListSchemasCommand.self,
            BasicObjectSchemaCommand.self,
            ArraySchemaCommand.self,
            EnumSchemaCommand.self
        ],
        defaultSubcommand: ListSchemasCommand.self
    )
}

struct ListSchemasCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List the shared schema demos and presets."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        let examples = FoundationLabSchemaExample.allCases.map { example in
            [
                "id": example.rawValue,
                "title": example.title,
                "summary": example.summary,
                "presets": example.presets.map { preset in
                    [
                        "id": preset.id,
                        "title": preset.title,
                        "defaultInput": preset.defaultInput
                    ]
                }
            ]
        }

        let human = humanReadableSchemaList()

        CLIOutput.emit(
            payload: ["schemas": examples],
            human: human,
            json: options.json
        )
    }
}

enum BasicObjectSchemaPreset: String, CaseIterable, ExpressibleByArgument {
    case person
    case product
    case custom

    var index: Int {
        switch self {
        case .person: 0
        case .product: 1
        case .custom: 2
        }
    }
}

struct BasicObjectSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "basic-object",
        abstract: "Run the shared basic object schema demo."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Schema input to analyze.")
    var input: String?

    @Option(name: .long, help: "Preset to use.")
    var preset: BasicObjectSchemaPreset = .person

    mutating func run() async throws {
        let example = FoundationLabSchemaExample.basicObject
        let presetInfo = example.preset(at: preset.index)
        let resolvedInput = try resolvedSchemaInput(input, example: example, presetIndex: preset.index)

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "schemas basic-object",
                    "preset": preset.rawValue,
                    "input": resolvedInput
                ],
                human: """
                [dry-run] fm schemas basic-object
                Preset: \(presetInfo.title)
                Input: \(resolvedInput)
                """,
                json: options.json
            )
            return
        }

        try await runSchemaCommand(
            example: example,
            presetIndex: preset.index,
            input: resolvedInput,
            presetTitle: presetInfo.title,
            options: options
        )
    }
}

enum ArraySchemaPreset: String, CaseIterable, ExpressibleByArgument {
    case todo
    case ingredients
    case tags

    var index: Int {
        switch self {
        case .todo: 0
        case .ingredients: 1
        case .tags: 2
        }
    }
}

struct ArraySchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "array-schema",
        abstract: "Run the shared array schema demo."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Schema input to analyze.")
    var input: String?

    @Option(name: .long, help: "Preset to use.")
    var preset: ArraySchemaPreset = .todo

    @Option(name: .customLong("min-items"), help: "Minimum number of generated items.")
    var minimumItems = 2

    @Option(name: .customLong("max-items"), help: "Maximum number of generated items.")
    var maximumItems = 5

    mutating func run() async throws {
        let example = FoundationLabSchemaExample.arraySchema
        let presetInfo = example.preset(at: preset.index)
        let resolvedInput = try resolvedSchemaInput(input, example: example, presetIndex: preset.index)

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "schemas array-schema",
                    "preset": preset.rawValue,
                    "input": resolvedInput,
                    "minimumItems": minimumItems,
                    "maximumItems": maximumItems
                ],
                human: """
                [dry-run] fm schemas array-schema
                Preset: \(presetInfo.title)
                Input: \(resolvedInput)
                Constraints: \(minimumItems)-\(maximumItems)
                """,
                json: options.json
            )
            return
        }

        try await runSchemaCommand(
            example: example,
            presetIndex: preset.index,
            input: resolvedInput,
            presetTitle: presetInfo.title,
            minimumElements: minimumItems,
            maximumElements: maximumItems,
            options: options
        )
    }
}

enum EnumSchemaPreset: String, CaseIterable, ExpressibleByArgument {
    case sentiment
    case priority
    case weather

    var index: Int {
        switch self {
        case .sentiment: 0
        case .priority: 1
        case .weather: 2
        }
    }
}

struct EnumSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enum-schema",
        abstract: "Run the shared enum schema demo."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "Schema input to analyze.")
    var input: String?

    @Option(name: .long, help: "Preset to use.")
    var preset: EnumSchemaPreset = .sentiment

    @Option(
        name: .customLong("choice"),
        parsing: .upToNextOption,
        help: "Custom choices to use instead of the preset list. Repeat for multiple values."
    )
    var choice: [String] = []

    mutating func run() async throws {
        let example = FoundationLabSchemaExample.enumSchema
        let presetInfo = example.preset(at: preset.index)
        let resolvedInput = try resolvedSchemaInput(input, example: example, presetIndex: preset.index)
        let customChoices = choice
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "schemas enum-schema",
                    "preset": preset.rawValue,
                    "input": resolvedInput,
                    "choices": customChoices
                ],
                human: """
                [dry-run] fm schemas enum-schema
                Preset: \(presetInfo.title)
                Input: \(resolvedInput)
                Choices: \((customChoices.isEmpty ? example.choices(for: preset.index) : customChoices).joined(separator: ", "))
                """,
                json: options.json
            )
            return
        }

        try await runSchemaCommand(
            example: example,
            presetIndex: preset.index,
            input: resolvedInput,
            presetTitle: presetInfo.title,
            customChoices: customChoices.isEmpty ? nil : customChoices,
            options: options
        )
    }
}

private func resolvedSchemaInput(
    _ input: String?,
    example: FoundationLabSchemaExample,
    presetIndex: Int
) throws -> String {
    let resolvedInput = input ?? example.preset(at: presetIndex).defaultInput
    return try validatedNonEmpty(resolvedInput, optionName: "--input")
}

private func runSchemaCommand(
    example: FoundationLabSchemaExample,
    presetIndex: Int,
    input: String,
    presetTitle: String,
    minimumElements: Int? = nil,
    maximumElements: Int? = nil,
    customChoices: [String]? = nil,
    options: CLIOptions
) async throws {
    do {
        try requireFoundationModelsAvailability()

        let result = try await RunSchemaExampleUseCase().execute(
            RunSchemaExampleRequest(
                example: example,
                presetIndex: presetIndex,
                input: input,
                minimumElements: minimumElements,
                maximumElements: maximumElements,
                customChoices: customChoices,
                context: cliContext()
            )
        )

        CLIOutput.emit(
            payload: [
                "example": example.rawValue,
                "preset": presetTitle,
                "input": input,
                "content": result.content,
                "metadata": metadataPayload(result.metadata)
            ],
            human: humanReadableSchemaResult(
                title: example.title,
                presetTitle: presetTitle,
                content: result.content,
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

private func humanReadableSchemaList() -> String {
    FoundationLabSchemaExample.allCases.map { example in
        let presets = example.presets
            .map { "  - \($0.title)" }
            .joined(separator: "\n")

        return """
        \(example.rawValue): \(example.title)
        \(example.summary)
        \(presets)
        """
    }
    .joined(separator: "\n\n")
}

private func humanReadableSchemaResult(
    title: String,
    presetTitle: String,
    content: String,
    metadata: CapabilityExecutionMetadata,
    verbose: Bool
) -> String {
    var lines = [title, "Preset: \(presetTitle)", "", content]

    if verbose {
        let provider = metadata.provider ?? "Unknown"
        let tokenCount = metadata.tokenCount.map(String.init) ?? "n/a"
        lines.append("")
        lines.append("Provider: \(provider)")
        lines.append("Token count: \(tokenCount)")
    }

    return lines.joined(separator: "\n")
}
