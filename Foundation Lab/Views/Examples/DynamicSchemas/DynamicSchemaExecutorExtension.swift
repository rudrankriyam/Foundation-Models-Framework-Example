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
        // Try to get as primitive types first
        if let stringValue = try? content.value(String.self) {
            return stringValue
        }
        
        if let intValue = try? content.value(Int.self) {
            return intValue
        }
        
        if let doubleValue = try? content.value(Double.self) {
            return doubleValue
        }
        
        if let floatValue = try? content.value(Float.self) {
            return floatValue
        }
        
        if let boolValue = try? content.value(Bool.self) {
            return boolValue
        }
        
        // Try as array
        if let elements = try? content.elements() {
            return try elements.map { try buildJSONObject(from: $0) }
        }
        
        // Try as object with properties
        if let properties = try? content.properties() {
            var jsonDict = [String: Any]()
            for (key, value) in properties {
                jsonDict[key] = try buildJSONObject(from: value)
            }
            return jsonDict
        }
        
        // If all else fails, return a string representation
        return String(describing: content)
    }
}