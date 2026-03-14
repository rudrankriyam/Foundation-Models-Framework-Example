import ArgumentParser
import FoundationLabCore

struct SearchContactsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search contacts."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The contact search query.")
    var query: String

    mutating func run() async throws {
        let trimmedQuery = try validatedNonEmpty(query, optionName: "--query")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "contacts search",
                    "query": trimmedQuery
                ],
                human: """
                [dry-run] fm contacts search
                Query: \(trimmedQuery)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Contacts")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct QueryCalendarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query calendar events."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The natural-language calendar request.")
    var request: String

    mutating func run() async throws {
        let trimmedRequest = try validatedNonEmpty(request, optionName: "--request")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "calendar query",
                    "request": trimmedRequest
                ],
                human: """
                [dry-run] fm calendar query
                Request: \(trimmedRequest)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Calendar")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct ManageRemindersCLICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "request",
        abstract: "Create or manage reminders."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The natural-language reminders request.")
    var prompt: String

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "reminders request",
                    "prompt": trimmedPrompt
                ],
                human: """
                [dry-run] fm reminders request
                Prompt: \(trimmedPrompt)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Reminders")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct GetCurrentLocationCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "current",
        abstract: "Get the current location."
    )

    @OptionGroup var options: CLIOptions

    mutating func run() async throws {
        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "location current"
                ],
                human: "[dry-run] fm location current",
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Location")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct SearchMusicCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search the Apple Music catalog."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The music search query.")
    var query: String

    mutating func run() async throws {
        let trimmedQuery = try validatedNonEmpty(query, optionName: "--query")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "music search",
                    "query": trimmedQuery
                ],
                human: """
                [dry-run] fm music search
                Query: \(trimmedQuery)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Music")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}

struct QueryHealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "query",
        abstract: "Query health data."
    )

    @OptionGroup var options: CLIOptions

    @Option(name: [.short, .long], help: "The health data question to ask.")
    var request: String

    mutating func run() async throws {
        let trimmedRequest = try validatedNonEmpty(request, optionName: "--request")

        if options.dryRun {
            CLIOutput.emit(
                payload: [
                    "status": "dry_run",
                    "command": "health query",
                    "request": trimmedRequest
                ],
                human: """
                [dry-run] fm health query
                Request: \(trimmedRequest)
                """,
                json: options.json
            )
            return
        }

        do {
            try requireUnsupportedCLICapability("Health")
        } catch {
            CLIOutput.emitError(error, json: options.json)
            throw ExitCode.failure
        }
    }
}
