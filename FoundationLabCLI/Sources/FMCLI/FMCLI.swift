import ArgumentParser

@main
struct FMCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "Work with Apple's Foundation Models from the command line.",
        discussion: CLIHelpText.root,
        subcommands: [
            StatusCommand.self,
            ModelCommand.self,
            SessionCommand.self,
            ToolsCommand.self,
            ExamplesCommand.self,
            SchemasCommand.self
        ]
    )
}
