import ArgumentParser
import Foundation
import FoundationModels

enum CLIOutputFormat: String, CaseIterable, Codable, ExpressibleByArgument {
    case text
    case json
}

struct CLIOutputOptions {
    let format: CLIOutputFormat
    let pretty: Bool
}

enum CLIOutput {
    static func resolve(output: CLIOutputFormat?, pretty: Bool) throws -> CLIOutputOptions {
        let format = output ?? defaultFormat()
        if pretty && format != .json {
            throw ValidationError("--pretty is only valid with JSON output")
        }
        return CLIOutputOptions(format: format, pretty: pretty)
    }

    static func emit<Payload: Encodable>(
        payload: Payload,
        human: String,
        options: CLIOutputOptions
    ) throws {
        switch options.format {
        case .text:
            if !human.isEmpty {
                print(human)
            }
        case .json:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            if options.pretty {
                encoder.outputFormatting.insert(.prettyPrinted)
            }
            let data = try encoder.encode(payload)
            if let text = String(data: data, encoding: .utf8) {
                print(text)
            } else {
                throw AFMRuntimeError.providerFailure("Failed to encode JSON output")
            }
        }
    }

    static func emitError(_ error: Error, format: CLIOutputFormat) {
        let message = afmErrorMessage(for: error)
        switch format {
        case .text:
            fputs("Error: \(message)\n", stderr)
        case .json:
            let payload = ErrorPayload(status: "error", message: message)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(payload),
               let text = String(data: data, encoding: .utf8) {
                fputs(text + "\n", stderr)
            } else {
                fputs("{\"status\":\"error\",\"message\":\"\(message)\"}\n", stderr)
            }
        }
    }

    private static func defaultFormat() -> CLIOutputFormat {
        let environment = ProcessInfo.processInfo.environment
        if environment["AFM_FORCE_TTY"] == "1" {
            return .text
        }
        if environment["AFM_FORCE_NON_TTY"] == "1" {
            return .json
        }

        return isatty(fileno(stdout)) == 1 ? .text : .json
    }
}

private struct ErrorPayload: Encodable {
    let status: String
    let message: String
}

func afmErrorMessage(for error: Error) -> String {
    if let afmError = error as? AFMRuntimeError {
        return afmError.errorDescription ?? String(describing: afmError)
    }
    if let validation = error as? ValidationError {
        return validation.description
    }
    if let generationError = error as? LanguageModelSession.GenerationError {
        return afmGenerationErrorMessage(generationError)
    }
    if let localized = error as? LocalizedError, let message = localized.errorDescription {
        return message
    }
    return error.localizedDescription
}

private func afmGenerationErrorMessage(_ error: LanguageModelSession.GenerationError) -> String {
    switch error {
    case .exceededContextWindowSize:
        return "The session exceeded the model context window. Start a new session, shorten prompts, or lower response length."
    case .assetsUnavailable:
        return "Foundation Models assets are unavailable right now. Verify availability and try again later."
    case .guardrailViolation:
        return "The request or response triggered Foundation Models guardrails."
    case .unsupportedGuide:
        return "The request used an unsupported generation guide."
    case .unsupportedLanguageOrLocale:
        return "The requested language or locale is not supported."
    case .decodingFailure:
        return "The model response could not be decoded into the requested structure."
    case .rateLimited:
        return "The request was rate limited."
    case .concurrentRequests:
        return "A second request was attempted while the session was already responding."
    case .refusal(let refusal, _):
        return "The model refused to answer. Use feedback export or inspect the refusal explanation. Transcript entries: \(refusal)"
    @unknown default:
        return error.localizedDescription
    }
}
