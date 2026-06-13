import ArgumentParser
import Foundation
import FoundationModels

struct ToolCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tool",
        abstract: "Inspect, validate, and call dynamic tool manifests.",
        subcommands: [
            ToolInspectCommand.self,
            ToolValidateCommand.self,
            ToolCallCommand.self
        ]
    )
}

struct ToolInspectPayload: Encodable {
    let command: String
    let name: String
    let description: String
    let file: String
    let runner: String
}

struct ToolValidatePayload: Encodable {
    struct ValidatedTool: Encodable {
        let name: String
        let file: String
    }

    let command: String
    let status: String
    let name: String
    let file: String
    let tools: [ValidatedTool]
}

struct ToolCallPayload: Encodable {
    let command: String
    let name: String
    let file: String
    let arguments: String
    let output: String
}

struct ToolArgumentsOptions: ParsableArguments {
    @Option(name: .long, help: "JSON arguments for the tool. Prefix the value with @ to read from a file.")
    var args: String?

    @Option(name: .customLong("args-file"), help: "Read JSON tool arguments from a file path.")
    var argsFile: String?

    @Flag(name: .long, help: "Read JSON tool arguments from standard input.")
    var stdin = false

    func resolve() throws -> ResolvedTextInput {
        guard let resolved = try resolveSingleInput(
            inlineValue: args,
            fileValue: argsFile,
            stdin: stdin,
            inlineOptionName: "--args",
            fileOptionName: "--args-file",
            requiredMessage: "Please provide --args, --args-file, or stdin."
        ) else {
            throw ValidationError("Please provide --args, --args-file, or stdin.")
        }
        return resolved
    }
}

struct ToolInspectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "Show a dynamic tool manifest."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let reference = try requireSingleToolReference(toolSource)
        let manifest = try AFMArtifactRegistry.loadToolManifest(from: reference)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "tool inspect",
                    toolFiles: [reference.filePath],
                    toolDirectory: reference.directory
                ),
                human: "[dry-run] afm tool inspect\nTool: \(reference.filePath)",
                options: resolvedOutput
            )
            return
        }

        let payload = ToolInspectPayload(
            command: "tool inspect",
            name: manifest.name,
            description: manifest.description,
            file: reference.filePath,
            runner: manifest.runner.kind.rawValue
        )
        let human = """
        Tool: \(manifest.name)
        File: \(reference.filePath)
        Runner: \(manifest.runner.kind.rawValue)

        \(manifest.description)
        """
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct ToolValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate one or more dynamic tool manifests."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let toolSet = try resolveToolManifests(toolSource)

        if toolSet.references.isEmpty {
            throw ValidationError("Please provide at least one --tool.")
        }

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "tool validate",
                    toolFiles: toolSet.references.map { $0.filePath },
                    toolDirectory: expandedPathString(toolSource.toolDir)
                ),
                human: "[dry-run] afm tool validate\nTools: \(toolSet.references.count)",
                options: resolvedOutput
            )
            return
        }

        let validatedTools = try zip(toolSet.references, toolSet.tools).map { reference, tool in
            guard let manifestTool = tool as? AFMManifestTool else {
                throw AFMRuntimeError.invalidRequest("Missing validated tool metadata")
            }
            return ToolValidatePayload.ValidatedTool(
                name: manifestTool.name,
                file: reference.filePath
            )
        }
        guard let first = validatedTools.first else {
            throw AFMRuntimeError.invalidRequest("Missing validated tool metadata")
        }
        let payload = ToolValidatePayload(
            command: "tool validate",
            status: "valid",
            name: first.name,
            file: first.file,
            tools: validatedTools
        )
        let human = toolSet.references
            .map { "Validated: \($0.filePath)" }
            .joined(separator: "\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct ToolCallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "call",
        abstract: "Execute one dynamic tool directly with JSON arguments."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var toolSource: ToolSourceOptions
    @OptionGroup var arguments: ToolArgumentsOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let reference = try requireSingleToolReference(toolSource)
        let manifestTool = try AFMManifestTool(
            manifest: AFMArtifactRegistry.loadToolManifest(from: reference),
            sourcePath: reference.filePath
        )
        let resolvedArguments = try arguments.resolve()
        let generatedArguments: GeneratedContent

        do {
            generatedArguments = try GeneratedContent(json: resolvedArguments.value)
        } catch {
            throw ValidationError("Could not decode tool arguments as JSON: \(error.localizedDescription)")
        }

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "tool call",
                    input: resolvedArguments.value,
                    inputFile: resolvedArguments.file,
                    toolFiles: [reference.filePath],
                    toolDirectory: reference.directory
                ),
                human: "[dry-run] afm tool call\nTool: \(reference.filePath)",
                options: resolvedOutput
            )
            return
        }

        let result = try await manifestTool.call(arguments: generatedArguments)
        let output = result.jsonString
        let payload = ToolCallPayload(
            command: "tool call",
            name: manifestTool.name,
            file: reference.filePath,
            arguments: generatedArguments.jsonString,
            output: output
        )
        let human = """
        Tool: \(manifestTool.name)
        File: \(reference.filePath)

        \(output)
        """
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

private func requireSingleToolReference(_ toolSource: ToolSourceOptions) throws -> ResolvedArtifactReference {
    let references = try toolSource.resolveTools()
    guard let reference = references.first else {
        throw ValidationError("Please provide one --tool.")
    }
    guard references.count == 1 else {
        throw ValidationError("Please provide exactly one --tool for this command.")
    }
    return reference
}
