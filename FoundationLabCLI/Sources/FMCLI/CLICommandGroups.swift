import ArgumentParser

struct CLIOptions: ParsableArguments {
    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    @Flag(name: .customLong("dry-run"), help: "Print the request without executing it.")
    var dryRun = false

    @Flag(name: .long, help: "Include execution metadata in human-readable output.")
    var verbose = false
}

struct SessionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session",
        abstract: "Create one-off, streaming, or multi-turn session responses.",
        discussion: CLIHelpText.session,
        subcommands: [
            SessionRespondCommand.self,
            SessionStreamCommand.self,
            SessionChatCommand.self
        ]
    )
}

struct ToolsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tools",
        abstract: "Use tool calling workflows backed by the shared core runtime.",
        discussion: CLIHelpText.tools,
        subcommands: [
            WeatherToolCommand.self,
            WebToolCommand.self
        ]
    )
}

struct WeatherToolCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Weather tool commands.",
        discussion: CLIHelpText.weather,
        subcommands: [
            GetWeatherCommand.self
        ]
    )
}

struct WebToolCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web",
        abstract: "Web tool commands.",
        discussion: CLIHelpText.web,
        subcommands: [
            SearchWebCommand.self,
            SummarizeWebPageCommand.self
        ]
    )
}
