import ArgumentParser

struct CLIOptions: ParsableArguments {
    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    @Flag(name: .customLong("dry-run"), help: "Print the request without executing it.")
    var dryRun = false

    @Flag(name: .long, help: "Include execution metadata in human-readable output.")
    var verbose = false
}

struct ToolsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tools",
        abstract: "Run the shared Foundation Lab tool demos.",
        subcommands: [
            WeatherToolCommand.self,
            WebToolCommand.self
        ]
    )
}

struct WeatherToolCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Weather tool demos.",
        subcommands: [
            GetWeatherCommand.self
        ],
        defaultSubcommand: GetWeatherCommand.self
    )
}

struct WebToolCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web",
        abstract: "Web tool demos.",
        subcommands: [
            SearchWebCommand.self,
            SummarizeWebPageCommand.self
        ],
        defaultSubcommand: SearchWebCommand.self
    )
}

struct ChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Multi-turn conversation capabilities.",
        subcommands: [
            RunChatCommand.self
        ],
        defaultSubcommand: RunChatCommand.self
    )
}
