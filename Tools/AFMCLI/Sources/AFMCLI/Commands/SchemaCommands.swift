import ArgumentParser
import Foundation
import FoundationLabCore
import FoundationModels

struct SchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schema",
        abstract: "Run typed and dynamic schema workflows.",
        discussion: HelpText.schema,
        subcommands: [
            SchemaListCommand.self,
            SchemaRunCommand.self
        ]
    )
}

struct SchemaListPayload: Encodable {
    let schemas: [AFMSchemaExampleDescriptor]
}

struct SchemaListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Show available typed and dynamic schema workflows."
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "schema list"),
                human: "[dry-run] afm schema list",
                options: resolvedOutput
            )
            return
        }
        let payload = SchemaListPayload(schemas: AFMSchemaCatalog.examples)
        var lines = AFMSchemaCatalog.examples.map { example in
            let presetNames = example.presets.map(\.id).joined(separator: ", ")
            return "\(example.id): \(example.title)\n  \(example.summary)\n  Presets: \(presetNames)"
        }
        if options.verbose {
            lines.append("Schema count: \(AFMSchemaCatalog.examples.count)")
        }
        let human = lines.joined(separator: "\n\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct SchemaRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Execute one schema workflow.",
        subcommands: [
            SchemaCustomCommand.self,
            TypedPersonSchemaCommand.self,
            BasicObjectSchemaCommand.self,
            ArraySchemaCommand.self,
            EnumSchemaCommand.self
        ]
    )
}

struct TypedSchemaPayload<Output: Encodable>: Encodable {
    let command: String
    let adapter: String?
    let preset: String
    let useCase: String
    let guardrails: String
    let includeSchemaInPrompt: Bool
    let input: String
    let output: Output
    let tokenCount: Int?
}

struct DynamicSchemaPayload: Encodable {
    let command: String
    let adapter: String?
    let preset: String
    let useCase: String
    let guardrails: String
    let includeSchemaInPrompt: Bool
    let input: String
    let json: String
    let tokenCount: Int?
    let schemaFile: String?
}

struct SchemaCustomCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "custom",
        abstract: "Run a dynamic schema loaded from a JSON or YAML file."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions
    @OptionGroup var schemaSource: SchemaSourceOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let schemaReference = try schemaSource.resolve()
        let schemaDocument = try AFMArtifactRegistry.loadSchemaDocument(from: schemaReference)
        let resolvedInput = try inputSource.resolve()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "schema run custom",
                    adapter: adapterPath,
                    input: resolvedInput.value,
                    inputFile: resolvedInput.file,
                    schema: schemaReference.identifier,
                    schemaFile: schemaReference.filePath,
                    schemaDirectory: schemaReference.directory,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
                ),
                human: "[dry-run] afm schema run custom\nSchema: \(schemaReference.filePath)\nInput: \(resolvedInput.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let result = try await GenerateDynamicSchemaContentUseCase().execute(
            DynamicSchemaGenerationRequest(
                prompt: resolvedInput.value,
                schema: try schemaDocument.generationSchema(fallbackName: schemaReference.identifier.camelizedSchemaName()),
                systemPrompt: generation.systemPrompt,
                modelUseCase: useCaseFlags.useCase,
                guardrails: generation.guardrails,
                adapterURL: adapterURL(from: adapterPath),
                generationOptions: generationOptions,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
                context: afmContext()
            )
        )

        let json = result.output.jsonString
        let payload = DynamicSchemaPayload(
            command: "schema run custom",
            adapter: adapterPath,
            preset: schemaReference.identifier,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
            input: resolvedInput.value,
            json: json,
            tokenCount: result.metadata.tokenCount,
            schemaFile: schemaReference.filePath
        )
        let human = """
        Custom Schema

        Schema: \(schemaReference.filePath)
        \(json)
        """
        let verboseHuman: String
        if options.verbose, let tokenCount = result.metadata.tokenCount {
            verboseHuman = "\(human)\n\nToken count: \(tokenCount)"
        } else {
            verboseHuman = human
        }
        try CLIOutput.emit(payload: payload, human: verboseHuman, options: resolvedOutput)
    }
}

struct TypedPersonSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "typed-person",
        abstract: "Run a typed @Generable person workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        guard let example = AFMSchemaCatalog.example(id: "typed-person"),
              let preset = example.presets.first else {
            throw AFMRuntimeError.invalidRequest("Missing typed-person schema preset")
        }
        let resolvedInput = try inputSource.resolve(defaultValue: preset.defaultInput)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "schema run typed-person",
                    adapter: adapterPath,
                    input: resolvedInput.value,
                    inputFile: resolvedInput.file,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
                ),
                human: "[dry-run] afm schema run typed-person\nInput: \(resolvedInput.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let result = try await GenerateStructuredDataUseCase<AFMGeneratedPerson>().execute(
            StructuredGenerationRequest(
                prompt: resolvedInput.value,
                systemPrompt: generation.systemPrompt,
                modelUseCase: useCaseFlags.useCase,
                guardrails: generation.guardrails,
                adapterURL: adapterURL(from: adapterPath),
                generationOptions: generationOptions,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
                context: afmContext()
            )
        )
        let payload = TypedSchemaPayload(
            command: "schema run typed-person",
            adapter: adapterPath,
            preset: preset.id,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
            input: resolvedInput.value,
            output: result.output,
            tokenCount: result.metadata.tokenCount
        )
        let human = """
        Typed Person

        Name: \(result.output.name)
        Age: \(result.output.age)
        Occupation: \(result.output.occupation)
        """
        let verboseHuman: String
        if options.verbose, let tokenCount = result.metadata.tokenCount {
            verboseHuman = "\(human)\n\nToken count: \(tokenCount)"
        } else {
            verboseHuman = human
        }
        try CLIOutput.emit(payload: payload, human: verboseHuman, options: resolvedOutput)
    }
}

struct BasicObjectSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "basic-object",
        abstract: "Run a runtime-defined basic object schema workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    @Option(name: .long, help: "Preset to use.")
    var preset = "person"

    mutating func run() async throws {
        try await runDynamicSchemaCommand(
            command: "schema run basic-object",
            exampleID: "basic-object",
            presetID: preset,
            inputSource: inputSource,
            schemaBuilder: makeBasicObjectSchema,
            options: options,
            generation: generation,
            adapterPath: try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails),
            useCase: useCaseFlags.useCase,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
        )
    }
}

struct ArraySchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "array-schema",
        abstract: "Run a runtime-defined array schema workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    @Option(name: .long, help: "Preset to use.")
    var preset = "todo"

    @Option(name: .customLong("min-items"), help: "Minimum number of generated items.")
    var minimumItems = 2

    @Option(name: .customLong("max-items"), help: "Maximum number of generated items.")
    var maximumItems = 5

    mutating func run() async throws {
        try await runDynamicSchemaCommand(
            command: "schema run array-schema",
            exampleID: "array-schema",
            presetID: preset,
            inputSource: inputSource,
            schemaBuilder: { presetID in
                try makeArraySchema(presetID: presetID, minimumItems: minimumItems, maximumItems: maximumItems)
            },
            options: options,
            generation: generation,
            adapterPath: try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails),
            useCase: useCaseFlags.useCase,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
        )
    }
}

struct EnumSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enum-schema",
        abstract: "Run a runtime-defined enum schema workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    @Option(name: .long, help: "Preset to use.")
    var preset = "sentiment"

    @Option(name: .customLong("choice"), parsing: .upToNextOption, help: "Custom enum choices. Repeat the option for multiple values.")
    var choice: [String] = []

    mutating func run() async throws {
        try await runDynamicSchemaCommand(
            command: "schema run enum-schema",
            exampleID: "enum-schema",
            presetID: preset,
            inputSource: inputSource,
            schemaBuilder: { presetID in
                try makeEnumSchema(
                    presetID: presetID,
                    customChoices: choice.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                )
            },
            options: options,
            generation: generation,
            adapterPath: try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails),
            useCase: useCaseFlags.useCase,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
        )
    }
}

private func runDynamicSchemaCommand(
    command: String,
    exampleID: String,
    presetID: String,
    inputSource: InputSourceOptions,
    schemaBuilder: (String) throws -> GenerationSchema,
    options: GlobalCommandOptions,
    generation: GenerationFlags,
    adapterPath: String?,
    useCase: FoundationLabModelUseCase,
    includeSchemaInPrompt: Bool
) async throws {
    let resolvedOutput = try options.resolvedOutput()
    let generationOptions = try generation.validatedOptions()
    guard let example = AFMSchemaCatalog.example(id: exampleID) else {
        throw AFMRuntimeError.invalidRequest("Unknown schema example: \(exampleID)")
    }
    guard let preset = example.presets.first(where: { $0.id == presetID }) else {
        throw ValidationError("Unknown preset '\(presetID)' for \(exampleID)")
    }
    let resolvedInput = try inputSource.resolve(defaultValue: preset.defaultInput)

    if options.dryRun {
        try CLIOutput.emit(
            payload: DryRunPayload(
                command: command,
                adapter: adapterPath,
                preset: presetID,
                input: resolvedInput.value,
                inputFile: resolvedInput.file,
                useCase: useCase.rawValue,
                guardrails: generation.guardrails.afmArgumentValue,
                includeSchemaInPrompt: includeSchemaInPrompt
            ),
            human: "[dry-run] afm \(command)\nPreset: \(presetID)\nInput: \(resolvedInput.value)",
            options: resolvedOutput
        )
        return
    }

    _ = try requireFoundationModelsAvailability(
        useCase: useCase,
        adapterPath: adapterPath
    )
    let result = try await GenerateDynamicSchemaContentUseCase().execute(
        DynamicSchemaGenerationRequest(
            prompt: resolvedInput.value,
            schema: try schemaBuilder(presetID),
            systemPrompt: generation.systemPrompt,
            modelUseCase: useCase,
            guardrails: generation.guardrails,
            adapterURL: adapterURL(from: adapterPath),
            generationOptions: generationOptions,
            includeSchemaInPrompt: includeSchemaInPrompt,
            context: afmContext()
        )
    )
    let payload = DynamicSchemaPayload(
        command: command,
        adapter: adapterPath,
        preset: presetID,
        useCase: useCase.rawValue,
        guardrails: generation.guardrails.afmArgumentValue,
        includeSchemaInPrompt: includeSchemaInPrompt,
        input: resolvedInput.value,
        json: result.output.jsonString,
        tokenCount: result.metadata.tokenCount,
        schemaFile: nil
    )
    let human = """
    \(example.title)

    \(result.output.jsonString)
    """
    let verboseHuman: String
    if options.verbose, let tokenCount = result.metadata.tokenCount {
        verboseHuman = "\(human)\n\nToken count: \(tokenCount)"
    } else {
        verboseHuman = human
    }
    try CLIOutput.emit(payload: payload, human: verboseHuman, options: resolvedOutput)
}

private func makeBasicObjectSchema(presetID: String) throws -> GenerationSchema {
    let root: DynamicGenerationSchema
    switch presetID {
    case "person":
        root = DynamicGenerationSchema(
            name: "Person",
            properties: [
                .init(name: "name", schema: .init(type: String.self)),
                .init(name: "age", schema: .init(type: Int.self)),
                .init(name: "occupation", schema: .init(type: String.self))
            ]
        )
    case "product":
        root = DynamicGenerationSchema(
            name: "Product",
            properties: [
                .init(name: "name", schema: .init(type: String.self)),
                .init(name: "price", schema: .init(type: Double.self)),
                .init(name: "feature", schema: .init(type: String.self))
            ]
        )
    default:
        throw ValidationError("Unknown preset '\(presetID)' for basic-object")
    }
    return try GenerationSchema(root: root, dependencies: [])
}

private func makeArraySchema(presetID: String, minimumItems: Int, maximumItems: Int) throws -> GenerationSchema {
    guard minimumItems > 0 else {
        throw ValidationError("--min-items must be greater than 0")
    }
    guard maximumItems >= minimumItems else {
        throw ValidationError("--max-items must be greater than or equal to --min-items")
    }

    let itemName: String = switch presetID {
    case "todo": "TodoItem"
    default: throw ValidationError("Unknown preset '\(presetID)' for array-schema")
    }

    let itemSchema = DynamicGenerationSchema(
        name: itemName,
        properties: [
            .init(name: "title", schema: .init(type: String.self)),
            .init(name: "completed", schema: .init(type: Bool.self), isOptional: true)
        ]
    )
    let root = DynamicGenerationSchema(
        name: "TodoList",
        properties: [
            .init(
                name: "items",
                schema: .init(arrayOf: .init(referenceTo: itemName), minimumElements: minimumItems, maximumElements: maximumItems)
            )
        ]
    )
    return try GenerationSchema(root: root, dependencies: [itemSchema])
}

private func makeEnumSchema(presetID: String, customChoices: [String]) throws -> GenerationSchema {
    let choices = customChoices.isEmpty ? AFMSchemaCatalog.defaultChoices(for: presetID) : customChoices
    let root = DynamicGenerationSchema(
        name: "Classification",
        properties: [
            .init(name: "label", schema: .init(name: "Label", anyOf: choices)),
            .init(name: "reason", schema: .init(type: String.self), isOptional: true)
        ]
    )
    return try GenerationSchema(root: root, dependencies: [])
}
