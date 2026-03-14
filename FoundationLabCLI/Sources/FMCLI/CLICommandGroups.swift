import ArgumentParser

struct CLIOptions: ParsableArguments {
    @Flag(name: .long, help: "Emit machine-readable JSON.")
    var json = false

    @Flag(name: .customLong("dry-run"), help: "Print the request without executing it.")
    var dryRun = false

    @Flag(name: .long, help: "Include execution metadata in human-readable output.")
    var verbose = false
}

struct BookCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "book",
        abstract: "Book recommendation capabilities.",
        subcommands: [
            RecommendBookCommand.self
        ],
        defaultSubcommand: RecommendBookCommand.self
    )
}

struct NutritionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "nutrition",
        abstract: "Nutrition analysis capabilities.",
        subcommands: [
            AnalyzeNutritionCommand.self
        ],
        defaultSubcommand: AnalyzeNutritionCommand.self
    )
}

struct WeatherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Weather capabilities.",
        subcommands: [
            GetWeatherCommand.self
        ],
        defaultSubcommand: GetWeatherCommand.self
    )
}

struct WebCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "web",
        abstract: "Web capabilities.",
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

struct ContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "contacts",
        abstract: "Contacts capabilities.",
        subcommands: [
            SearchContactsCommand.self
        ],
        defaultSubcommand: SearchContactsCommand.self
    )
}

struct CalendarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendar",
        abstract: "Calendar capabilities.",
        subcommands: [
            QueryCalendarCommand.self
        ],
        defaultSubcommand: QueryCalendarCommand.self
    )
}

struct RemindersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reminders",
        abstract: "Reminders capabilities.",
        subcommands: [
            ManageRemindersCLICommand.self
        ],
        defaultSubcommand: ManageRemindersCLICommand.self
    )
}

struct LocationCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "location",
        abstract: "Location capabilities.",
        subcommands: [
            GetCurrentLocationCommand.self
        ],
        defaultSubcommand: GetCurrentLocationCommand.self
    )
}

struct MusicCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music",
        abstract: "Music capabilities.",
        subcommands: [
            SearchMusicCommand.self
        ],
        defaultSubcommand: SearchMusicCommand.self
    )
}

struct HealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "health",
        abstract: "Health capabilities.",
        subcommands: [
            QueryHealthCommand.self
        ],
        defaultSubcommand: QueryHealthCommand.self
    )
}
