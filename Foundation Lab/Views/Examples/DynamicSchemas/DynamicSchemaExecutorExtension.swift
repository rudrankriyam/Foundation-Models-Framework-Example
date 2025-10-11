//
//  DynamicSchemaExecutorExtension.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import Foundation
import FoundationModels

extension ExampleExecutor {
    /// Convenience property to match the naming used in dynamic schema examples
    var results: String {
        get { result }
        set { result = newValue }
    }

    /// Convenience method to match the naming used in dynamic schema examples
    func reset() {
        clear()
    }

    /// Execute a custom async operation and capture the result
    func execute(_ operation: @escaping () async throws -> String) async {
        isRunning = true
        errorMessage = nil
        result = ""

        do {
            result = try await operation()
        } catch {
            errorMessage = handleError(error)
        }

        isRunning = false
    }

    /// Execute with a DynamicGenerationSchema
    func execute(
        withPrompt prompt: String,
        schema: DynamicGenerationSchema,
        formatResults: ((String) -> String)? = nil
    ) async {
        isRunning = true
        errorMessage = nil
        result = ""

        do {
            let session = LanguageModelSession()
            let generationSchema = try GenerationSchema(root: schema, dependencies: [])
            let output = try await session.respond(
                to: Prompt(prompt),
                schema: generationSchema
            )

            // Format the output content properly
            if let formatResults = formatResults {
                result = formatResults(formatGeneratedContent(output.content))
            } else {
                result = formatGeneratedContent(output.content)
            }
        } catch {
            errorMessage = handleError(error)
        }

        isRunning = false
    }

    /// Helper to format GeneratedContent as JSON string
    private func formatGeneratedContent(_ content: GeneratedContent) -> String {
        do {
            // Build a proper JSON object from the GeneratedContent
            let jsonObject = try buildJSONObject(from: content)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
            return String(describing: jsonObject)
        } catch {
            return "Error formatting content: \(error.localizedDescription)"
        }
    }

    /// Recursively build a JSON-compatible object from GeneratedContent
    private func buildJSONObject(from content: GeneratedContent) throws -> Any {
        switch content.kind {
        case .string(let stringValue):
            return stringValue
        case .number(let numValue):
            return numValue
        case .bool(let boolValue):
            return boolValue
        case .null:
            return NSNull()
        case .array(let elements):
            return try elements.map { try buildJSONObject(from: $0) }
        case .structure(let properties, let orderedKeys):
            var jsonDict = [String: Any]()
            for key in orderedKeys {
                if let value = properties[key] {
                    jsonDict[key] = try buildJSONObject(from: value)
                }
            }
            return jsonDict
        @unknown default:
            return String(describing: content)
        }
    }
}
