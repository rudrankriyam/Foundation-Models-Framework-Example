import ArgumentParser
import Foundation

struct RootStatusPayload: Encodable {
    let name: String
    let summary: String
    let commands: [String]
}

struct AFMRootCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "afm",
        abstract: "A powerful command-line interface for Foundation Models on Apple platforms.",
        discussion: HelpText.root,
        version: "0.1.0",
        subcommands: [
            ModelCommand.self,
            SessionCommand.self,
            SchemaCommand.self,
            TranscriptCommand.self,
            FeedbackCommand.self
        ]
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let payload = RootStatusPayload(
            name: Self.configuration.commandName ?? "afm",
            summary: "Workflow-first CLI for Foundation Models sessions, schemas, transcripts, and feedback.",
            commands: ["model", "session", "schema", "transcript", "feedback"]
        )

        try CLIOutput.emit(
            payload: payload,
            human: HelpText.root,
            options: resolvedOutput
        )
    }
}
