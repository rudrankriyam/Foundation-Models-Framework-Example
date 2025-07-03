//
//  BasicDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct BasicDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var personInput = "John Doe is 32 years old, works as a software engineer and loves hiking."
    @State private var productInput = "The iPhone 15 Pro costs $999 and has a 6.1 inch display"
    @State private var customInput = ""
    @State private var selectedExample = 0
    
    private let examples = ["Person", "Product", "Custom"]
    
    var body: some View {
        ExampleViewBase(
            title: "Basic Object Schema",
            description: "Create simple object schemas at runtime using DynamicGenerationSchema",
            defaultPrompt: personInput,
            currentPrompt: .constant(currentInput),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0 }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)
                
                // Input based on selection
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: bindingForSelectedExample)
                        .font(.body)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Schema preview
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Generated Schema")
                        .font(.headline)
                    
                    Text(schemaDescription)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                HStack {
                    Button("Extract Data") {
                        Task {
                            await runExample()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(executor.isRunning || currentInput.isEmpty)
                    
                    if executor.isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
        }
    }
    
    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $personInput
        case 1: return $productInput
        default: return $customInput
        }
    }
    
    private var currentInput: String {
        switch selectedExample {
        case 0: return personInput
        case 1: return productInput
        default: return customInput
        }
    }
    
    private var schemaDescription: String {
        switch selectedExample {
        case 0:
            return """
            {
              "name": "Person",
              "type": "object",
              "properties": {
                "name": { "type": "string", "description": "The person's full name" },
                "age": { "type": "integer", "description": "The person's age in years" },
                "occupation": { "type": "string", "description": "The person's job or profession" },
                "hobbies": { "type": "array", "items": { "type": "string" }, "description": "List of hobbies" }
              }
            }
            """
        case 1:
            return """
            {
              "name": "Product",
              "type": "object",
              "properties": {
                "name": { "type": "string", "description": "Product name" },
                "price": { "type": "number", "description": "Price in USD" },
                "specifications": { "type": "object", "description": "Product specs" }
              }
            }
            """
        default:
            return """
            {
              "name": "CustomObject",
              "type": "object",
              "properties": {
                "field1": { "type": "string", "description": "A text field" },
                "field2": { "type": "integer", "description": "A number field" }
              }
            }
            """
        }
    }
    
    private func runExample() async {
        await executor.execute {
            let schema = try createSchema(for: selectedExample)
            let session = LanguageModelSession()
            
            let prompt = """
            Extract the following information from this text:
            
            \(currentInput)
            """
            
            let response = try await session.respond(
                to: Prompt(prompt),
                schema: schema,
                options: .init(temperature: 0.1)
            )
            
            return """
            📝 Input:
            \(currentInput)
            
            📊 Extracted Data:
            \(formatContent(response.content))
            
            🔍 Schema Used:
            \(selectedExample == 0 ? "Person" : selectedExample == 1 ? "Product" : "CustomObject")
            """
        }
    }
    
    private func createSchema(for index: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            // Person schema
            let nameProperty = DynamicGenerationSchema.Property(
                name: "name",
                description: "The person's full name",
                schema: .init(type: String.self)
            )
            
            let ageProperty = DynamicGenerationSchema.Property(
                name: "age",
                description: "The person's age in years",
                schema: .init(type: Int.self)
            )
            
            let occupationProperty = DynamicGenerationSchema.Property(
                name: "occupation",
                description: "The person's job or profession",
                schema: .init(type: String.self)
            )
            
            let hobbiesProperty = DynamicGenerationSchema.Property(
                name: "hobbies",
                description: "List of hobbies or interests",
                schema: .init(arrayOf: .init(type: String.self))
            )
            
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "Information about a person",
                properties: [nameProperty, ageProperty, occupationProperty, hobbiesProperty]
            )
            
            return try GenerationSchema(root: personSchema, dependencies: [])
            
        case 1:
            // Product schema
            let nameProperty = DynamicGenerationSchema.Property(
                name: "name",
                description: "Product name",
                schema: .init(type: String.self)
            )
            
            let priceProperty = DynamicGenerationSchema.Property(
                name: "price",
                description: "Price in USD",
                schema: .init(type: Float.self)
            )
            
            // Nested specifications object
            let specsProperties = [
                DynamicGenerationSchema.Property(
                    name: "display_size",
                    description: "Display size if mentioned",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "other_specs",
                    description: "Any other specifications",
                    schema: .init(arrayOf: .init(type: String.self)),
                    isOptional: true
                )
            ]
            
            let specsSchema = DynamicGenerationSchema(
                name: "Specifications",
                description: "Product specifications",
                properties: specsProperties
            )
            
            let specsProperty = DynamicGenerationSchema.Property(
                name: "specifications",
                description: "Product specifications",
                schema: specsSchema
            )
            
            let productSchema = DynamicGenerationSchema(
                name: "Product",
                description: "Product information",
                properties: [nameProperty, priceProperty, specsProperty]
            )
            
            return try GenerationSchema(root: productSchema, dependencies: [specsSchema])
            
        default:
            // Custom simple schema
            let field1 = DynamicGenerationSchema.Property(
                name: "field1",
                description: "A text field",
                schema: .init(type: String.self)
            )
            
            let field2 = DynamicGenerationSchema.Property(
                name: "field2",
                description: "A number field",
                schema: .init(type: Int.self)
            )
            
            let customSchema = DynamicGenerationSchema(
                name: "CustomObject",
                description: "A custom object",
                properties: [field1, field2]
            )
            
            return try GenerationSchema(root: customSchema, dependencies: [])
        }
    }
    
    private func formatContent(_ content: GeneratedContent) -> String {
        // Format the generated content for display
        do {
            let properties = try content.properties()
            var result = "{\n"
            for (key, value) in properties {
                result += "  \"\(key)\": \(formatValue(value)),\n"
            }
            result = String(result.dropLast(2)) // Remove last comma and newline
            result += "\n}"
            return result
        } catch {
            return "Error formatting content: \(error)"
        }
    }
    
    private func formatValue(_ content: GeneratedContent) -> String {
        do {
            // Try to get as string first
            if let stringValue = try? content.value(String.self) {
                return "\"\(stringValue)\""
            }
            
            // Try as number
            if let intValue = try? content.value(Int.self) {
                return String(intValue)
            }
            
            if let floatValue = try? content.value(Float.self) {
                return String(floatValue)
            }
            
            // Try as array
            if let elements = try? content.elements() {
                let formatted = elements.map { formatValue($0) }.joined(separator: ", ")
                return "[\(formatted)]"
            }
            
            // Try as object
            if let properties = try? content.properties() {
                var result = "{ "
                for (key, value) in properties {
                    result += "\"\(key)\": \(formatValue(value)), "
                }
                result = String(result.dropLast(2)) // Remove last comma and space
                result += " }"
                return result
            }
            
            return "unknown"
        } catch {
            return "error"
        }
    }
    
    private var exampleCode: String {
        """
        // Creating a basic object schema at runtime
        let nameProperty = DynamicGenerationSchema.Property(
            name: "name",
            description: "The person's full name",
            schema: .init(type: String.self)
        )
        
        let ageProperty = DynamicGenerationSchema.Property(
            name: "age",
            description: "The person's age in years",
            schema: .init(type: Int.self)
        )
        
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            description: "Information about a person",
            properties: [nameProperty, ageProperty]
        )
        
        // Convert to GenerationSchema for use with LanguageModelSession
        let schema = try GenerationSchema(root: personSchema, dependencies: [])
        
        // Use the schema to extract structured data
        let response = try await session.respond(
            to: "John is 25 years old",
            schema: schema
        )
        """
    }
}

#Preview {
    NavigationStack {
        BasicDynamicSchemaView()
    }
}