import Foundation
import Testing

struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

@Test("Root help shows grouped command discovery")
func rootHelpShowsGroupedCommands() throws {
    let result = try runAFM("--help")

    #expect(result.status == 0)
    #expect(result.stdout.contains("MODEL COMMANDS"))
    #expect(result.stdout.contains("SESSION COMMANDS"))
    #expect(result.stdout.contains("SCHEMA COMMANDS"))
    #expect(result.stdout.contains("EXPORT COMMANDS"))
    #expect(result.stdout.contains("afm model status"))
}

@Test("Root dry-run emits a request shape instead of normal help output")
func rootDryRun() throws {
    let result = try runAFM("--output", "json", "--dry-run")

    #expect(result.status == 0)
    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "afm")
    #expect(json["status"] as? String == "dry_run")
}

@Test("Leaf command help covers every shipped public workflow")
func leafCommandHelpCoverage() throws {
    let commands: [[String]] = [
        ["model", "status", "--help"],
        ["model", "languages", "--help"],
        ["session", "respond", "--help"],
        ["session", "stream", "--help"],
        ["session", "chat", "--help"],
        ["schema", "list", "--help"],
        ["schema", "run", "typed-person", "--help"],
        ["schema", "run", "basic-object", "--help"],
        ["schema", "run", "array-schema", "--help"],
        ["schema", "run", "enum-schema", "--help"],
        ["transcript", "export", "--help"],
        ["feedback", "export", "--help"]
    ]

    for command in commands {
        let result = try runAFM(command)
        #expect(result.status == 0)
        #expect(result.stdout.contains("USAGE:"))
        #expect(result.stdout.contains("--help"))
        if command.contains("session")
            || command == ["schema", "run", "typed-person", "--help"]
            || command == ["schema", "run", "basic-object", "--help"]
            || command == ["schema", "run", "array-schema", "--help"]
            || command == ["schema", "run", "enum-schema", "--help"]
            || command.contains("transcript")
            || command.contains("feedback") {
            #expect(result.stdout.contains("--guardrails <guardrails>"))
        }
    }
}

@Test("Model and schema discovery commands honor dry-run")
func discoveryCommandsHonorDryRun() throws {
    let status = try runAFM("model", "status", "--output", "json", "--dry-run")
    let languages = try runAFM("model", "languages", "--output", "json", "--dry-run")
    let schemaList = try runAFM("schema", "list", "--output", "json", "--dry-run")

    #expect(status.status == 0)
    #expect(languages.status == 0)
    #expect(schemaList.status == 0)

    #expect((try parseJSONObject(status.stdout))["command"] as? String == "model status")
    #expect((try parseJSONObject(languages.stdout))["command"] as? String == "model languages")
    #expect((try parseJSONObject(schemaList.stdout))["command"] as? String == "schema list")
}

@Test("TTY-aware defaults choose text for terminals and json for pipes")
func ttyAwareOutputDefaults() throws {
    let textResult = try runAFM(
        "session", "respond", "--dry-run", "--prompt", "hi",
        environment: ["AFM_FORCE_TTY": "1"]
    )
    let jsonResult = try runAFM(
        "session", "respond", "--dry-run", "--prompt", "hi",
        environment: ["AFM_FORCE_NON_TTY": "1"]
    )

    #expect(textResult.status == 0)
    #expect(textResult.stdout.contains("[dry-run] afm session respond"))
    #expect(!textResult.stdout.contains("\"status\":\"dry_run\""))

    #expect(jsonResult.status == 0)
    #expect(jsonResult.stdout.contains("\"status\":\"dry_run\""))
    #expect(jsonResult.stdout.contains("\"command\":\"session respond\""))
}

@Test("Pretty JSON output emits formatted JSON when explicitly requested")
func prettyJSONOutput() throws {
    let result = try runAFM(
        "session", "respond", "--output", "json", "--pretty", "--dry-run", "--prompt", "hi"
    )

    #expect(result.status == 0)
    #expect(result.stdout.contains("\n  \"command\" : \"session respond\""))
    #expect(result.stdout.contains("\n  \"status\" : \"dry_run\""))
}

@Test("Verbose mode adds extra operator-facing detail")
func verboseModeAddsDetail() throws {
    let status = try runAFM("model", "status", "--verbose", environment: ["AFM_FORCE_TTY": "1"])
    let schemaList = try runAFM("schema", "list", "--verbose", environment: ["AFM_FORCE_TTY": "1"])

    #expect(status.status == 0)
    #expect(schemaList.status == 0)
    #expect(status.stdout.contains("Provider: Foundation Models"))
    #expect(schemaList.stdout.contains("Schema count:"))
}

@Test("Output and generation flags validate before runtime work starts")
func validationErrorsAreDeterministic() throws {
    let prettyResult = try runAFM("--output", "text", "--pretty", "model", "status")
    let temperatureResult = try runAFM("session", "respond", "--prompt", "hi", "--temperature", "2")
    let seedResult = try runAFM("session", "respond", "--prompt", "hi", "--seed", "1")

    #expect(prettyResult.status == 64)
    #expect(prettyResult.stderr.contains("--pretty is only valid with JSON output"))

    #expect(temperatureResult.status == 64)
    #expect(temperatureResult.stderr.contains("--temperature must be between 0 and 1"))

    #expect(seedResult.status == 64)
    #expect(seedResult.stderr.contains("--seed is only valid with non-greedy sampling"))
}

@Test("Session commands parse naturally in dry-run mode")
func sessionDryRunCommands() throws {
    let respond = try runAFM(
        "session", "respond", "--output", "json", "--dry-run", "--prompt", "Summarize this."
    )
    let stream = try runAFM(
        "session", "stream", "--output", "json", "--dry-run", "--prompt", "Stream this."
    )
    let chat = try runAFM(
        "session", "chat", "--output", "json", "--dry-run",
        "--message", "Hello",
        "--message", "Now answer in French."
    )

    #expect(respond.status == 0)
    #expect(stream.status == 0)
    #expect(chat.status == 0)

    let respondJSON = try parseJSONObject(respond.stdout)
    let streamJSON = try parseJSONObject(stream.stdout)
    let chatJSON = try parseJSONObject(chat.stdout)

    #expect(respondJSON["command"] as? String == "session respond")
    #expect(streamJSON["command"] as? String == "session stream")
    #expect(chatJSON["command"] as? String == "session chat")
    #expect((chatJSON["messages"] as? [String]) == ["Hello", "Now answer in French."])
}

@Test("Schema commands expose list and run flows")
func schemaCommands() throws {
    let list = try runAFM("schema", "list", "--output", "json")
    let typedPerson = try runAFM(
        "schema", "run", "typed-person", "--output", "json", "--dry-run",
        "--input", "Jane is a designer in Berlin."
    )
    let badPreset = try runAFM(
        "schema", "run", "enum-schema", "--dry-run", "--preset", "missing"
    )

    #expect(list.status == 0)
    #expect(typedPerson.status == 0)
    #expect(badPreset.status == 64)
    #expect(badPreset.stderr.contains("Unknown preset 'missing' for enum-schema"))

    let listJSON = try parseJSONObject(list.stdout)
    let typedJSON = try parseJSONObject(typedPerson.stdout)

    let schemas = listJSON["schemas"] as? [[String: Any]]
    #expect((schemas?.isEmpty == false))
    #expect(typedJSON["command"] as? String == "schema run typed-person")
    #expect(typedJSON["input"] as? String == "Jane is a designer in Berlin.")
}

@Test("All dynamic schema workflows dry-run cleanly")
func dynamicSchemaDryRuns() throws {
    let basic = try runAFM(
        "schema", "run", "basic-object", "--output", "json", "--dry-run", "--preset", "product"
    )
    let array = try runAFM(
        "schema", "run", "array-schema", "--output", "json", "--dry-run", "--preset", "todo",
        "--min-items", "2", "--max-items", "4"
    )
    let enumeration = try runAFM(
        "schema", "run", "enum-schema", "--output", "json", "--dry-run",
        "--choice", "high", "--choice", "medium", "--choice", "low"
    )

    #expect(basic.status == 0)
    #expect(array.status == 0)
    #expect(enumeration.status == 0)

    let basicJSON = try parseJSONObject(basic.stdout)
    let arrayJSON = try parseJSONObject(array.stdout)
    let enumJSON = try parseJSONObject(enumeration.stdout)

    #expect(basicJSON["command"] as? String == "schema run basic-object")
    #expect(arrayJSON["command"] as? String == "schema run array-schema")
    #expect(enumJSON["command"] as? String == "schema run enum-schema")
}

@Test("Transcript and feedback export validate file paths up front")
func exportCommandsValidateFilePaths() throws {
    let transcript = try runAFM(
        "transcript", "export", "--message", "hi", "--file", "", "--dry-run"
    )
    let feedback = try runAFM(
        "feedback", "export", "--prompt", "hi", "--file", "", "--dry-run"
    )

    #expect(transcript.status == 64)
    #expect(transcript.stderr.contains("Please provide a non-empty --file."))

    #expect(feedback.status == 64)
    #expect(feedback.stderr.contains("Please provide a non-empty --file."))
}

@Test("Export commands dry-run with explicit file paths")
func exportCommandsDryRun() throws {
    let transcript = try runAFM(
        "transcript", "export", "--output", "json", "--dry-run",
        "--message", "hello", "--file", "/tmp/afm-test-transcript.json"
    )
    let feedback = try runAFM(
        "feedback", "export", "--output", "json", "--dry-run",
        "--prompt", "hello", "--file", "/tmp/afm-test-feedback.json"
    )

    #expect(transcript.status == 0)
    #expect(feedback.status == 0)

    let transcriptJSON = try parseJSONObject(transcript.stdout)
    let feedbackJSON = try parseJSONObject(feedback.stdout)

    #expect(transcriptJSON["command"] as? String == "transcript export")
    #expect(transcriptJSON["file"] as? String == "/tmp/afm-test-transcript.json")
    #expect(feedbackJSON["command"] as? String == "feedback export")
    #expect(feedbackJSON["file"] as? String == "/tmp/afm-test-feedback.json")
}

@Test("Feedback export creates nested parent directories")
func feedbackExportCreatesNestedDirectories() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-feedback-\(UUID().uuidString)")
    let file = directory.appending(path: "nested/output/feedback.json")

    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let result = try runAFM(
        "feedback", "export",
        "--output", "json",
        "--prompt", "What is the capital of France?",
        "--file", file.path()
    )

    #expect(result.status == 0)
    #expect(FileManager.default.fileExists(atPath: file.path()))

    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "feedback export")
    #expect(json["file"] as? String == file.path())
}

@Test("Streaming JSON mode emits event lines instead of buffering silently")
func streamingJSONEmitsEvents() throws {
    let stream = try runAFM(
        "session", "stream",
        "--output", "json",
        "--prompt", "Reply with exactly: streamed ok."
    )
    let chat = try runAFM(
        "session", "chat",
        "--stream",
        "--output", "json",
        "--message", "Hello",
        "--message", "Answer with exactly: done."
    )

    #expect(stream.status == 0)
    #expect(chat.status == 0)

    let streamEvents = try parseJSONLines(stream.stdout)
    let chatEvents = try parseJSONLines(chat.stdout)

    #expect((streamEvents.first?["event"] as? String) == "started")
    #expect(streamEvents.contains { ($0["event"] as? String) == "delta" })
    #expect((streamEvents.last?["event"] as? String) == "completed")

    #expect(chatEvents.contains { ($0["event"] as? String) == "message_started" })
    #expect(chatEvents.contains { ($0["event"] as? String) == "message_delta" })
    #expect(chatEvents.contains { ($0["event"] as? String) == "message_completed" })
    #expect((chatEvents.last?["event"] as? String) == "session_completed")
}

@Test("Unknown commands suggest the closest valid command")
func unknownCommandSuggestions() throws {
    let root = try runAFM("modle")
    let nested = try runAFM("session", "repond")

    #expect(root.status == 64)
    #expect(root.stderr.contains("Did you mean 'model'?"))

    #expect(nested.status == 64)
    #expect(nested.stderr.contains("Did you mean 'session respond'?"))
}

@Test("Model commands run against the live framework surface")
func modelCommandsReturnStructuredJSON() throws {
    let status = try runAFM("model", "status", "--output", "json")
    let languages = try runAFM("model", "languages", "--output", "json")

    #expect(status.status == 0)
    #expect(languages.status == 0)

    let statusJSON = try parseJSONObject(status.stdout)
    let languagesJSON = try parseJSONObject(languages.stdout)

    #expect(statusJSON["status"] as? String != nil)
    #expect(statusJSON["reason"] as? String != nil)

    let supportedLanguages = languagesJSON["languages"] as? [[String: Any]]
    #expect((supportedLanguages?.isEmpty == false))
    #expect(languagesJSON["currentLanguage"] as? String != nil)
}

private func runAFM(
    _ arguments: String...,
    environment: [String: String] = [:]
) throws -> CommandResult {
    try runAFM(arguments, environment: environment)
}

private func runAFM(
    _ arguments: [String],
    environment: [String: String] = [:]
) throws -> CommandResult {
    let process = Process()
    process.executableURL = try findAFMBinary()
    process.currentDirectoryURL = packageRoot()
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    process.arguments = arguments

    try process.run()
    process.waitUntilExit()

    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    return CommandResult(
        status: process.terminationStatus,
        stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines),
        stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines)
    )
}

private func parseJSONObject(_ text: String) throws -> [String: Any] {
    let data = try #require(text.data(using: .utf8))
    let object = try JSONSerialization.jsonObject(with: data)
    return try #require(object as? [String: Any])
}

private func parseJSONLines(_ text: String) throws -> [[String: Any]] {
    let lines = text
        .split(separator: "\n")
        .map(String.init)
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    return try lines.map(parseJSONObject)
}

private func findAFMBinary() throws -> URL {
    let root = packageRoot()
    let directCandidates = [
        root.appending(path: ".build/debug/afm"),
        root.appending(path: ".build/arm64-apple-macosx/debug/afm"),
        root.appending(path: ".build/x86_64-apple-macosx/debug/afm")
    ]

    for candidate in directCandidates where FileManager.default.isExecutableFile(atPath: candidate.path()) {
        return candidate
    }

    let buildRoot = root.appending(path: ".build")
    if let enumerator = FileManager.default.enumerator(at: buildRoot, includingPropertiesForKeys: nil) {
        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == "afm" {
            if FileManager.default.isExecutableFile(atPath: fileURL.path()) {
                return fileURL
            }
        }
    }

    throw TestFailure("Could not find built afm executable under \(buildRoot.path())")
}

private func packageRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
