import ArgumentParser

@main
struct FMCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fm",
        abstract: "Run Foundation Lab shared capabilities from the command line.",
        subcommands: [
            StatusCommand.self,
            BookCommand.self,
            NutritionCommand.self,
            WeatherCommand.self,
            WebCommand.self,
            ExamplesCommand.self,
            SchemasCommand.self,
            LanguagesCommand.self,
            ChatCommand.self,
            ContactsCommand.self,
            CalendarCommand.self,
            RemindersCommand.self,
            LocationCommand.self,
            MusicCommand.self,
            HealthCommand.self
        ],
        defaultSubcommand: BookCommand.self
    )
}
