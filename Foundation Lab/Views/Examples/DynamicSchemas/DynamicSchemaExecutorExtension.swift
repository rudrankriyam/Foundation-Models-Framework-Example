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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
        
        isRunning = false
    }
    
    /// Helper to format GeneratedContent as JSON string
    private func formatGeneratedContent(_ content: GeneratedContent) -> String {
        // Attempt to convert to JSON
        do {
            let properties = try content.properties()
            let jsonData = try JSONSerialization.data(withJSONObject: properties, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? (try? content.value(String.self)) ?? "Unable to format"
        } catch {
            // Fallback to simple string value
            return (try? content.value(String.self)) ?? "Error: \(error)"
        }
    }
}