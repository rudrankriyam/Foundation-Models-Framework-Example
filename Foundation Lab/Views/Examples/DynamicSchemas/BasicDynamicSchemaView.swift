//
//  BasicDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
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
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: {
                selectedExample = 0
                personInput = "John Doe is 32 years old, works as a software engineer and loves hiking."
                productInput = "The iPhone 15 Pro costs $999 and has a 6.1 inch display"
                customInput = ""
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)

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

                // Results section
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 250)
                    }
                }
            }
            .padding()
        }
    )
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
    }

    private func createSchema(for index: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            // Person schema
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "Information about a person",
                properties: [
                    .init(name: "name", description: "The person's full name", schema: .init(type: String.self)),
                    .init(name: "age", description: "The person's age in years", schema: .init(type: Int.self)),
                    .init(name: "occupation", description: "The person's job or profession", schema: .init(type: String.self)),
                    .init(name: "hobbies", description: "List of hobbies or interests", schema: .init(arrayOf: .init(type: String.self)))
                ]
            )
            return try GenerationSchema(root: personSchema, dependencies: [])

        case 1:
            // Product schema
            let specsSchema = DynamicGenerationSchema(
                name: "Specifications",
                description: "Product specifications",
                properties: [
                    .init(name: "display_size",
                          description: "Display size if mentioned",
                          schema: .init(type: String.self),
                          isOptional: true),
                    .init(name: "other_specs",
                          description: "Any other specifications",
                          schema: .init(arrayOf: .init(type: String.self)),
                          isOptional: true)
                ]
            )

            let productSchema = DynamicGenerationSchema(
                name: "Product",
                description: "Product information",
                properties: [
                    .init(name: "name", description: "Product name", schema: .init(type: String.self)),
                    .init(name: "price", description: "Price in USD", schema: .init(type: Float.self)),
                    .init(name: "specifications", description: "Product specifications", schema: specsSchema)
                ]
            )
            return try GenerationSchema(root: productSchema, dependencies: [specsSchema])

        default:
            // Custom simple schema
            let customSchema = DynamicGenerationSchema(
                name: "CustomObject",
                description: "A custom object",
                properties: [
                    .init(name: "field1", description: "A text field", schema: .init(type: String.self)),
                    .init(name: "field2", description: "A number field", schema: .init(type: Int.self))
                ]
            )
            return try GenerationSchema(root: customSchema, dependencies: [])
        }
    }

    private func formatContent(_ content: GeneratedContent) -> String {
        // Format the generated content for display
        switch content.kind {
        case .structure(let properties, let orderedKeys):
            var result = "{\n"
            for key in orderedKeys {
                if let value = properties[key] {
                    result += "  \"\(key)\": \(formatValue(value)),\n"
                }
            }
            result = String(result.dropLast(2)) // Remove last comma and newline
            result += "\n}"
            return result
        default:
            return "Error: Expected object structure"
        }
    }

    private func formatValue(_ content: GeneratedContent) -> String {
        switch content.kind {
        case .string(let stringValue):
            return "\"\(stringValue)\""
        case .number(let numValue):
            return String(numValue)
        case .bool(let boolValue):
            return String(boolValue)
        case .array(let elements):
            let formatted = elements.map { formatValue($0) }.joined(separator: ", ")
            return "[\(formatted)]"
        case .structure(let properties, let orderedKeys):
            var result = "{ "
            for key in orderedKeys {
                if let value = properties[key] {
                    result += "\"\(key)\": \(formatValue(value)), "
                }
            }
            result = String(result.dropLast(2)) // Remove last comma and space
            result += " }"
            return result
        case .null:
            return "null"
        @unknown default:
            return "unknown"
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
            to: prompt, // Uses the actual user input
            schema: schema
        )
        """
    }

#Preview {
    NavigationStack {
        BasicDynamicSchemaView()
    }
}
