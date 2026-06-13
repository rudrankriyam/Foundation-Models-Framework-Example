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
    #expect(result.stdout.contains("TOOL COMMANDS"))
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
        ["model", "use-cases", "--help"],
        ["model", "guardrails", "--help"],
        ["tag", "run", "--help"],
        ["session", "respond", "--help"],
        ["session", "stream", "--help"],
        ["session", "chat", "--help"],
        ["schema", "list", "--help"],
        ["schema", "run", "custom", "--help"],
        ["schema", "run", "typed-person", "--help"],
        ["schema", "run", "basic-object", "--help"],
        ["schema", "run", "array-schema", "--help"],
        ["schema", "run", "enum-schema", "--help"],
        ["tool", "inspect", "--help"],
        ["tool", "validate", "--help"],
        ["tool", "call", "--help"],
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
            || command == ["schema", "run", "custom", "--help"]
            || command.contains("transcript")
            || command.contains("feedback")
            || command == ["tag", "run", "--help"] {
            #expect(result.stdout.contains("--guardrails <guardrails>"))
        }
        if command.contains("session")
            || command.contains("feedback")
            || command.contains("transcript")
            || command.contains("schema")
            || command == ["model", "status", "--help"]
            || command == ["model", "languages", "--help"] {
            #expect(result.stdout.contains("--use-case <use-case>") || command.contains("schema"))
        }
        if command == ["schema", "run", "custom", "--help"]
            || command == ["schema", "run", "typed-person", "--help"]
            || command == ["schema", "run", "basic-object", "--help"]
            || command == ["schema", "run", "array-schema", "--help"]
            || command == ["schema", "run", "enum-schema", "--help"] {
            #expect(result.stdout.contains("--include-schema-in-prompt"))
        }
        if command.contains("session")
            || command.contains("feedback")
            || command.contains("transcript")
            || command == ["schema", "run", "custom", "--help"]
            || command == ["schema", "run", "typed-person", "--help"]
            || command == ["schema", "run", "basic-object", "--help"]
            || command == ["schema", "run", "array-schema", "--help"]
            || command == ["schema", "run", "enum-schema", "--help"]
            || command == ["tag", "run", "--help"] {
            #expect(result.stdout.contains("--adapter <adapter>"))
        }
    }
}

@Test("Model and schema discovery commands honor dry-run")
func discoveryCommandsHonorDryRun() throws {
    let status = try runAFM("model", "status", "--output", "json", "--dry-run")
    let languages = try runAFM("model", "languages", "--output", "json", "--dry-run")
    let useCases = try runAFM("model", "use-cases", "--output", "json", "--dry-run")
    let guardrails = try runAFM("model", "guardrails", "--output", "json", "--dry-run")
    let schemaList = try runAFM("schema", "list", "--output", "json", "--dry-run")

    #expect(status.status == 0)
    #expect(languages.status == 0)
    #expect(useCases.status == 0)
    #expect(guardrails.status == 0)
    #expect(schemaList.status == 0)

    #expect((try parseJSONObject(status.stdout))["command"] as? String == "model status")
    #expect((try parseJSONObject(languages.stdout))["command"] as? String == "model languages")
    #expect((try parseJSONObject(useCases.stdout))["command"] as? String == "model use-cases")
    #expect((try parseJSONObject(guardrails.stdout))["command"] as? String == "model guardrails")
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

@Test("Prompt and message sources resolve from files and stdin")
func promptAndMessageSourceResolution() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-inputs-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let promptFile = directory.appending(path: "prompt.txt")
    let messageFile = directory.appending(path: "message.txt")
    try "Prompt from file".write(to: promptFile, atomically: true, encoding: .utf8)
    try "Message from file".write(to: messageFile, atomically: true, encoding: .utf8)

    let promptFromFile = try runAFM(
        ["session", "respond", "--output", "json", "--dry-run", "--prompt", "@\(promptFile.path())"]
    )
    let promptFromStdin = try runAFM(
        ["session", "respond", "--output", "json", "--dry-run"],
        environment: ["AFM_FORCE_NON_TTY": "1"],
        stdin: "Prompt from stdin\n"
    )
    let chatFromFile = try runAFM(
        ["session", "chat", "--output", "json", "--dry-run", "--message-file", messageFile.path()]
    )

    #expect(promptFromFile.status == 0)
    #expect(promptFromStdin.status == 0)
    #expect(chatFromFile.status == 0)

    let fileJSON = try parseJSONObject(promptFromFile.stdout)
    let stdinJSON = try parseJSONObject(promptFromStdin.stdout)
    let chatJSON = try parseJSONObject(chatFromFile.stdout)

    #expect(fileJSON["prompt"] as? String == "Prompt from file")
    #expect(fileJSON["promptFile"] as? String == promptFile.path())
    #expect(stdinJSON["prompt"] as? String == "Prompt from stdin")
    #expect((chatJSON["messageFiles"] as? [String]) == [messageFile.path()])
    #expect((chatJSON["messages"] as? [String]) == ["Message from file"])
}

@Test("Adapter paths validate early and appear in dry-run payloads")
func adapterDryRunAndValidation() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-adapters-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let adapterPath = directory.appending(path: "Demo.fmadapter")
    let invalidPath = directory.appending(path: "Demo.txt")
    try FileManager.default.createDirectory(at: adapterPath, withIntermediateDirectories: true)
    try Data().write(to: invalidPath)

    let valid = try runAFM(
        ["session", "respond", "--output", "json", "--dry-run", "--adapter", adapterPath.path(), "--prompt", "hello"]
    )
    let invalid = try runAFM(
        ["session", "respond", "--dry-run", "--adapter", invalidPath.path(), "--prompt", "hello"]
    )
    let unsupportedGuardrails = try runAFM(
        [
            "session", "respond", "--dry-run",
            "--adapter", adapterPath.path(),
            "--guardrails", "permissive-content-transformations",
            "--prompt", "hello"
        ]
    )

    #expect(valid.status == 0)
    #expect(invalid.status == 64)
    #expect(unsupportedGuardrails.status == 64)

    let validJSON = try parseJSONObject(valid.stdout)
    #expect(validJSON["adapter"] as? String == adapterPath.path())
    #expect(invalid.stderr.contains("--adapter must point to a .fmadapter package"))
    #expect(
        unsupportedGuardrails.stderr.contains(
            "--adapter only supports the framework's default guardrails"
        )
    )
}

@Test("Schema commands expose list and run flows")
func schemaCommands() throws {
    let list = try runAFM("schema", "list", "--output", "json")
    let typedPerson = try runAFM(
        "schema", "run", "typed-person", "--output", "json", "--dry-run",
        "--input", "Alex Rivera is a designer in Berlin."
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
    #expect(typedJSON["input"] as? String == "Alex Rivera is a designer in Berlin.")
}

@Test("Foundation Models flags surface in dry-run payloads")
func foundationModelsFlagsSurfaceInDryRunPayloads() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-fmf-\(UUID().uuidString)")
    let schemaDirectory = directory.appending(path: ".afm/schemas")
    defer { try? FileManager.default.removeItem(at: directory) }
    try FileManager.default.createDirectory(at: schemaDirectory, withIntermediateDirectories: true)

    let schema = """
    title: PersonCard
    type: object
    properties:
      name:
        type: string
    required:
      - name
    """
    try schema.write(to: schemaDirectory.appending(path: "person-card.yaml"), atomically: true, encoding: .utf8)

    let modelStatus = try runAFM(
        "model", "status", "--output", "json", "--dry-run",
        "--use-case", "content-tagging"
    )
    let customSchema = try runAFM(
        "schema", "run", "custom", "--output", "json", "--dry-run",
        "--schema", "person-card",
        "--schema-dir", schemaDirectory.path(),
        "--input", "Alex Rivera",
        "--use-case", "content-tagging",
        "--no-include-schema-in-prompt"
    )
    let feedback = try runAFM(
        "feedback", "export", "--output", "json", "--dry-run",
        "--prompt", "hello",
        "--file", "/tmp/afm-feedback.json",
        "--issue", "incorrect",
        "--issue-explanation", "Wrong answer"
    )
    let tag = try runAFM(
        "tag", "run", "--output", "json", "--dry-run",
        "--prompt", "A joyful dog playing in a sunny park."
    )

    #expect(modelStatus.status == 0)
    #expect(customSchema.status == 0)
    #expect(feedback.status == 0)
    #expect(tag.status == 0)

    let modelJSON = try parseJSONObject(modelStatus.stdout)
    let schemaJSON = try parseJSONObject(customSchema.stdout)
    let feedbackJSON = try parseJSONObject(feedback.stdout)
    let tagJSON = try parseJSONObject(tag.stdout)

    #expect(modelJSON["useCase"] as? String == "content-tagging")
    #expect(schemaJSON["useCase"] as? String == "content-tagging")
    #expect(schemaJSON["includeSchemaInPrompt"] as? Bool == false)
    #expect((feedbackJSON["feedbackIssues"] as? [String]) == ["incorrect"])
    #expect(tagJSON["command"] as? String == "tag run")
    #expect(tagJSON["useCase"] as? String == "content-tagging")
}

@Test("Custom schema files resolve from schema-dir and dry-run cleanly")
func customSchemaFilesResolve() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-schemas-\(UUID().uuidString)")
    let schemaDirectory = directory.appending(path: ".afm/schemas")
    let inputFile = directory.appending(path: "input.txt")

    try FileManager.default.createDirectory(at: schemaDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let schema = """
    title: PersonCard
    type: object
    properties:
      name:
        type: string
      age:
        type: integer
      occupation:
        type: string
    required:
      - name
      - age
      - occupation
    """
    try schema.write(to: schemaDirectory.appending(path: "person-card.yaml"), atomically: true, encoding: .utf8)
    try "Alex Rivera is a 34-year-old designer in Berlin.".write(to: inputFile, atomically: true, encoding: .utf8)

    let result = try runAFM(
        "schema", "run", "custom",
        "--output", "json",
        "--dry-run",
        "--schema", "person-card",
        "--schema-dir", schemaDirectory.path(),
        "--input", "@\(inputFile.path())"
    )

    #expect(result.status == 0)
    let json = try parseJSONObject(result.stdout)
    #expect(json["command"] as? String == "schema run custom")
    #expect(json["schema"] as? String == "person-card")
    #expect(json["schemaFile"] as? String == schemaDirectory.appending(path: "person-card.yaml").path())
    #expect(json["input"] as? String == "Alex Rivera is a 34-year-old designer in Berlin.")
    #expect(json["inputFile"] as? String == inputFile.path())
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

@Test("Tool manifests validate, inspect, and call through the CLI")
func toolManifestCommands() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appending(path: "afm-tools-\(UUID().uuidString)")
    let toolDirectory = directory.appending(path: ".afm/tools")
    let argsFile = directory.appending(path: "args.json")

    try FileManager.default.createDirectory(at: toolDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let toolManifest = """
    name: echo_json
    description: Echoes JSON arguments back to the caller.
    parameters:
      title: EchoPayload
      type: object
      properties:
        city:
          type: string
      required:
        - city
    runner:
      kind: shell
      outputFormat: json
      command: /bin/sh
      args:
        - -lc
        - cat
    """
    let secondToolManifest = toolManifest.replacingOccurrences(
        of: "name: echo_json",
        with: "name: echo_json_two"
    )
    try toolManifest.write(to: toolDirectory.appending(path: "echo-json.yaml"), atomically: true, encoding: .utf8)
    try secondToolManifest.write(
        to: toolDirectory.appending(path: "echo-json-two.yaml"),
        atomically: true,
        encoding: .utf8
    )
    try #"{"city":"Berlin"}"#.write(to: argsFile, atomically: true, encoding: .utf8)

    let inspect = try runAFM(
        "tool", "inspect", "--output", "json",
        "--tool", "echo-json",
        "--tool-dir", toolDirectory.path()
    )
    let validate = try runAFM(
        "tool", "validate", "--output", "json",
        "--tool", "echo-json",
        "--tool", "echo-json-two",
        "--tool-dir", toolDirectory.path()
    )
    let call = try runAFM(
        "tool", "call", "--output", "json",
        "--tool", "echo-json",
        "--tool-dir", toolDirectory.path(),
        "--args-file", argsFile.path()
    )

    #expect(inspect.status == 0)
    #expect(validate.status == 0)
    #expect(call.status == 0)

    let inspectJSON = try parseJSONObject(inspect.stdout)
    let validateJSON = try parseJSONObject(validate.stdout)
    let callJSON = try parseJSONObject(call.stdout)
    let validatedTools = try #require(validateJSON["tools"] as? [[String: Any]])
    let echoedOutput = try #require(callJSON["output"] as? String)
    let echoedJSON = try parseJSONObject(echoedOutput)

    #expect(inspectJSON["name"] as? String == "echo_json")
    #expect(validateJSON["status"] as? String == "valid")
    #expect(validatedTools.count == 2)
    #expect(validatedTools.compactMap { $0["name"] as? String } == ["echo_json", "echo_json_two"])
    #expect(
        validatedTools.compactMap { $0["file"] as? String } == [
            toolDirectory.appending(path: "echo-json.yaml").path(),
            toolDirectory.appending(path: "echo-json-two.yaml").path()
        ]
    )
    #expect(callJSON["name"] as? String == "echo_json")
    #expect(echoedJSON["city"] as? String == "Berlin")
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
    let useCases = try runAFM("model", "use-cases", "--output", "json")
    let guardrails = try runAFM("model", "guardrails", "--output", "json")

    #expect(status.status == 0)
    #expect(languages.status == 0)
    #expect(useCases.status == 0)
    #expect(guardrails.status == 0)

    let statusJSON = try parseJSONObject(status.stdout)
    let languagesJSON = try parseJSONObject(languages.stdout)
    let useCasesJSON = try parseJSONObject(useCases.stdout)
    let guardrailsJSON = try parseJSONObject(guardrails.stdout)

    #expect(statusJSON["status"] as? String != nil)
    #expect(statusJSON["reason"] as? String != nil)
    #expect(statusJSON["useCase"] as? String != nil)

    let supportedLanguages = languagesJSON["languages"] as? [[String: Any]]
    #expect((supportedLanguages?.isEmpty == false))
    #expect(languagesJSON["currentLanguage"] as? String != nil)
    #expect(languagesJSON["useCase"] as? String != nil)
    #expect((useCasesJSON["useCases"] as? [[String: Any]])?.isEmpty == false)
    #expect((guardrailsJSON["guardrails"] as? [[String: Any]])?.isEmpty == false)
}

private func runAFM(
    _ arguments: String...,
    environment: [String: String] = [:],
    stdin: String? = nil
) throws -> CommandResult {
    try runAFM(arguments, environment: environment, stdin: stdin)
}

private func runAFM(
    _ arguments: [String],
    environment: [String: String] = [:],
    stdin: String? = nil
) throws -> CommandResult {
    let process = Process()
    process.executableURL = try findAFMBinary()
    process.currentDirectoryURL = packageRoot()
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }

    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    if let stdin {
        let stdinPipe = Pipe()
        process.standardInput = stdinPipe
        stdinPipe.fileHandleForWriting.write(Data(stdin.utf8))
        try? stdinPipe.fileHandleForWriting.close()
    }
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
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

    while directory.path != "/" {
        let manifest = directory.appending(path: "Package.swift")
        if FileManager.default.fileExists(atPath: manifest.path()) {
            return directory
        }
        directory.deleteLastPathComponent()
    }

    preconditionFailure("Could not find the package root above \(#filePath)")
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
