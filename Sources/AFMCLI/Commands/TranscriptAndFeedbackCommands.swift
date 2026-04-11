import ArgumentParser
import Foundation
import FoundationModels

struct TranscriptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transcript",
        abstract: "Export transcript data from a session flow.",
        subcommands: [
            TranscriptExportCommand.self
        ]
    )
}

struct ExportedTranscriptPayload: Encodable {
    struct Entry: Encodable {
        let role: String
        let content: String
    }

    let command: String
    let messages: [String]
    let entries: [Entry]
    let sessionCount: Int
    let tokenCount: Int
}

struct TranscriptExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Run a chat flow and write transcript JSON to a file."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var outputFile: TranscriptFileFlags

    @Option(name: .long, parsing: .upToNextOption, help: "Message(s) to send through one shared session before exporting.")
    var message: [String] = []

    mutating func run() async throws {
        let messages = try validatedNonEmptyValues(message, optionName: "--message")
        let exportPath = try validatedExportPath(outputFile.file)
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "transcript export", messages: messages, file: exportPath),
                human: "[dry-run] afm transcript export\nFile: \(exportPath)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability()
        let engine = await MainActor.run {
            AFMConversationEngine(configuration: defaultConversationConfiguration(systemPrompt: generation.systemPrompt))
        }

        for entry in messages {
            _ = try await engine.sendMessage(entry, generationOptions: generationOptions)
        }

        let entries = await MainActor.run { transcriptPayload(engine.session.transcript) }
        let sessionCount = await MainActor.run { engine.sessionCount }
        let tokenCount = await MainActor.run { engine.currentTokenCount }
        let payload = ExportedTranscriptPayload(
            command: "transcript export",
            messages: messages,
            entries: entries.map { entry in
                ExportedTranscriptPayload.Entry(role: entry.role, content: entry.content)
            },
            sessionCount: sessionCount,
            tokenCount: tokenCount
        )

        try writeJSONFile(payload, to: exportPath)
        let human = """
        Transcript exported
        File: \(exportPath)
        Entries: \(entries.count)
        """
        let verboseHuman: String
        if options.verbose {
            verboseHuman = """
            \(human)
            Sessions: \(sessionCount)
            Token count: \(tokenCount)
            """
        } else {
            verboseHuman = human
        }
        try CLIOutput.emit(payload: payload, human: verboseHuman, options: resolvedOutput)
    }
}

struct FeedbackCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "feedback",
        abstract: "Export Foundation Models feedback attachments.",
        subcommands: [
            FeedbackExportCommand.self
        ]
    )
}

struct FeedbackExportSummaryPayload: Encodable {
    let command: String
    let prompt: String
    let sentiment: String?
    let file: String
    let bytes: Int
}

struct FeedbackExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Run one prompt and export a Feedback Assistant attachment."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var outputFile: TranscriptFileFlags

    @Option(name: .long, help: "Prompt to send before exporting feedback.")
    var prompt: String

    @Option(name: .long, help: "Optional feedback sentiment.")
    var sentiment: CLIFeedbackSentiment?

    @Option(name: .customLong("desired-output"), help: "Optional desired output to include with the feedback.")
    var desiredOutput: String?

    mutating func run() async throws {
        let trimmedPrompt = try validatedNonEmpty(prompt, optionName: "--prompt")
        let exportPath = try validatedExportPath(outputFile.file)
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "feedback export", prompt: trimmedPrompt, file: exportPath),
                human: "[dry-run] afm feedback export\nFile: \(exportPath)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability()
        let model = SystemLanguageModel(
            useCase: AFMModelUseCase.general.foundationModelsValue,
            guardrails: generation.guardrails.foundationModelsValue
        )
        let session = makeFeedbackSession(model: model, systemPrompt: generation.systemPrompt)
        if let generationOptions {
            _ = try await session.respond(to: trimmedPrompt, options: generationOptions.foundationModelsValue)
        } else {
            _ = try await session.respond(to: trimmedPrompt)
        }

        let desiredEntry: Transcript.Entry?
        if let desiredOutput, !desiredOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            desiredEntry = Transcript.Entry.response(Transcript.Response(assetIDs: [], segments: [
                .text(.init(content: desiredOutput))
            ]))
        } else {
            desiredEntry = nil
        }

        let data = session.logFeedbackAttachment(
            sentiment: sentiment?.foundationModelsValue,
            desiredOutput: desiredEntry
        )
        try writeFileData(data, to: exportPath)

        let payload = FeedbackExportSummaryPayload(
            command: "feedback export",
            prompt: trimmedPrompt,
            sentiment: sentiment?.rawValue,
            file: exportPath,
            bytes: data.count
        )
        let human = """
        Feedback exported
        File: \(exportPath)
        Bytes: \(data.count)
        """
        let verboseHuman: String
        if options.verbose {
            let sentimentValue = sentiment?.rawValue ?? "unspecified"
            verboseHuman = """
            \(human)
            Sentiment: \(sentimentValue)
            """
        } else {
            verboseHuman = human
        }
        try CLIOutput.emit(payload: payload, human: verboseHuman, options: resolvedOutput)
    }
}

private func makeFeedbackSession(model: SystemLanguageModel, systemPrompt: String?) -> LanguageModelSession {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        return LanguageModelSession(model: model, instructions: trimmedSystemPrompt)
    }
    return LanguageModelSession(model: model)
}

private func writeJSONFile<Payload: Encodable>(_ payload: Payload, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(payload)
    try writeFileData(data, to: path)
}

private func writeFileData(_ data: Data, to path: String) throws {
    let url = try preparedOutputURL(for: path)

    do {
        try data.write(to: url, options: .atomic)
    } catch {
        throw AFMRuntimeError.fileWriteFailed(error.localizedDescription)
    }
}

private func preparedOutputURL(for path: String) throws -> URL {
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty else {
        throw AFMRuntimeError.invalidRequest("Missing export file path")
    }

    let url = URL(fileURLWithPath: trimmedPath)
    let directoryURL = url.deletingLastPathComponent()

    do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    } catch {
        throw AFMRuntimeError.fileWriteFailed(error.localizedDescription)
    }

    return url
}
