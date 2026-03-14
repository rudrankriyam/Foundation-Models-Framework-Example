import ArgumentParser

@main
struct FMCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "Run Foundation Lab shared capabilities from the command line.",
        discussion: CLIHelpText.root,
        subcommands: [
            StatusCommand.self,
            ToolsCommand.self,
            ExamplesCommand.self,
            SchemasCommand.self,
            LanguagesCommand.self,
            ChatCommand.self
        ]
    )
}
