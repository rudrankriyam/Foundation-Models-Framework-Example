//
//  OptionalFieldsSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct OptionalFieldsSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var userProfileInput = "Sarah Johnson, 28 years old, from San Francisco. Works as a Product Manager. Enjoys hiking and photography."
    @State private var productListingInput = "MacBook Pro M3, starting at $1999. Available in Space Gray and Silver."
    @State private var eventInput = "Tech Conference 2024 on March 15. Registration required. Early bird discount available."
    @State private var selectedExample = 0
    @State private var includeOptionalFields = true

    private let examples = ["User Profile", "Product Listing", "Event Details"]

    var body: some View {
        ExampleViewBase(
            title: "Optional vs Required Fields",
            description: "Learn how to handle optional and required fields in dynamic schemas",
            defaultPrompt: userProfileInput,
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0; includeOptionalFields = true }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                // Optional fields toggle
                Toggle("Request Optional Fields", isOn: $includeOptionalFields)
                    .font(.caption)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                // Schema preview
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Schema Structure")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(schemaFields, id: \.name) { field in
                            HStack {
                                Image(systemName: field.isOptional ? "questionmark.circle" : "checkmark.circle.fill")
                                    .foregroundColor(field.isOptional ? .orange : .green)
                                    .font(.caption)

                                Text(field.name)
                                    .font(.system(.caption, design: .monospaced))

                                Text(field.isOptional ? "(optional)" : "(required)")
                                    .font(.caption2)
                                    .foregroundColor(field.isOptional ? .orange : .green)

                                Spacer()

                                Text(field.type)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(8)
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
    }


    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $userProfileInput
        case 1: return $productListingInput
        default: return $eventInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return userProfileInput
        case 1: return productListingInput
        default: return eventInput
        }
    }

    private struct SchemaField {
        let name: String
        let type: String
        let isOptional: Bool
    }

    private var schemaFields: [SchemaField] {
        switch selectedExample {
        case 0: // User Profile
            return [
                SchemaField(name: "name", type: "String", isOptional: false),
                SchemaField(name: "age", type: "Int", isOptional: false),
                SchemaField(name: "location", type: "String", isOptional: true),
                SchemaField(name: "occupation", type: "String", isOptional: true),
                SchemaField(name: "bio", type: "String", isOptional: true),
                SchemaField(name: "interests", type: "[String]", isOptional: true)
            ]
        case 1: // Product Listing
            return [
                SchemaField(name: "name", type: "String", isOptional: false),
                SchemaField(name: "price", type: "Float", isOptional: false),
                SchemaField(name: "description", type: "String", isOptional: true),
                SchemaField(name: "colors", type: "[String]", isOptional: true),
                SchemaField(name: "inStock", type: "Bool", isOptional: true),
                SchemaField(name: "discount", type: "Float", isOptional: true)
            ]
        default: // Event Details
            return [
                SchemaField(name: "title", type: "String", isOptional: false),
                SchemaField(name: "date", type: "String", isOptional: false),
                SchemaField(name: "venue", type: "String", isOptional: true),
                SchemaField(name: "capacity", type: "Int", isOptional: true),
                SchemaField(name: "registration", type: "String", isOptional: true),
                SchemaField(name: "earlyBird", type: "Bool", isOptional: true)
            ]
        }
    }

    private func runExample() async {
        await executor.execute {
            let schema = try createSchema(for: selectedExample)
            let session = LanguageModelSession()

            let prompt = includeOptionalFields ?
            "Extract all available information from this text, including optional details:" :
            "Extract only the essential required information from this text:"

            let response = try await session.respond(
                to: Prompt("\(prompt)\n\n\(currentInput)"),
                schema: schema,
                options: .init(temperature: 0.1)
            )

            let properties = try response.content.properties()
            var extractedFields: [(String, String, Bool)] = []

            // Check which fields were extracted
            for field in schemaFields {
                if let value = properties[field.name] {
                    let valueStr = formatFieldValue(value)
                    extractedFields.append((field.name, valueStr, field.isOptional))
                } else if !field.isOptional {
                    extractedFields.append((field.name, "<missing required field>", field.isOptional))
                }
            }

            return """
            📝 Input:
            \(currentInput)
            
            🔍 Extraction Mode: \(includeOptionalFields ? "All Fields" : "Required Only")
            
            📊 Extracted Fields:
            \(formatExtractedFields(extractedFields))
            
            ✅ Schema Validation:
            • Required fields: \(schemaFields.filter { !$0.isOptional }.count)
            • Optional fields: \(schemaFields.filter { $0.isOptional }.count)
            • Fields extracted: \(extractedFields.filter { $0.1 != "<missing required field>" }.count)
            • Missing required: \(extractedFields.filter { $0.1 == "<missing required field>" }.count)
            """
        }
    }

    private func createSchema(for index: Int) throws -> GenerationSchema {
        let properties: [DynamicGenerationSchema.Property]

        switch index {
        case 0: // User Profile
            properties = [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "The person's full name",
                    schema: .init(type: String.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "age",
                    description: "The person's age",
                    schema: .init(type: Int.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "location",
                    description: "Where the person is from or lives",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "occupation",
                    description: "The person's job or profession",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "bio",
                    description: "Brief biographical information",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "interests",
                    description: "Hobbies or interests mentioned",
                    schema: .init(arrayOf: .init(type: String.self)),
                    isOptional: true
                )
            ]

        case 1: // Product Listing
            properties = [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Product name",
                    schema: .init(type: String.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Product price",
                    schema: .init(type: Float.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "description",
                    description: "Product description",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "colors",
                    description: "Available colors",
                    schema: .init(arrayOf: .init(type: String.self)),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "inStock",
                    description: "Whether the product is in stock",
                    schema: .init(type: Bool.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "discount",
                    description: "Discount percentage if any",
                    schema: .init(type: Float.self),
                    isOptional: true
                )
            ]

        default: // Event Details
            properties = [
                DynamicGenerationSchema.Property(
                    name: "title",
                    description: "Event title",
                    schema: .init(type: String.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "date",
                    description: "Event date",
                    schema: .init(type: String.self),
                    isOptional: false
                ),
                DynamicGenerationSchema.Property(
                    name: "venue",
                    description: "Event location or venue",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "capacity",
                    description: "Maximum attendees",
                    schema: .init(type: Int.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "registration",
                    description: "Registration requirements",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "earlyBird",
                    description: "Early bird discount available",
                    schema: .init(type: Bool.self),
                    isOptional: true
                )
            ]
        }

        // We can't filter properties based on isOptional since it's not stored
        // So we'll handle this in the prompt instead

        let schemaName = index == 0 ? "UserProfile" : index == 1 ? "ProductListing" : "EventDetails"
        let schema = DynamicGenerationSchema(
            name: schemaName,
            description: "Extract \(includeOptionalFields ? "all" : "required") information",
            properties: properties
        )

        return try GenerationSchema(root: schema, dependencies: [])
    }

    private func formatFieldValue(_ content: GeneratedContent) -> String {
        if let str = try? content.value(String.self) {
            return "\"\(str)\""
        } else if let num = try? content.value(Int.self) {
            return String(num)
        } else if let float = try? content.value(Float.self) {
            return String(format: "%.2f", float)
        } else if let bool = try? content.value(Bool.self) {
            return bool ? "true" : "false"
        } else if let array = try? content.elements() {
            let items = array.compactMap { try? $0.value(String.self) }
            return "[\(items.joined(separator: ", "))]"
        }
        return "<unknown>"
    }

    private func formatExtractedFields(_ fields: [(String, String, Bool)]) -> String {
        fields.map { field in
            let icon = field.2 ? "○" : "●" // Optional vs Required
            let status = field.1.contains("missing") ? "Missing" : "Present"
            return "\(icon) \(field.0): \(field.1) \(status)"
        }.joined(separator: "\n")
    }

    private var exampleCode: String {
        """
        // Creating schemas with optional fields
        let userSchema = DynamicGenerationSchema(
            name: "UserProfile",
            description: "User information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Full name",
                    schema: .init(type: String.self),
                    isOptional: false  // Required field
                ),
                DynamicGenerationSchema.Property(
                    name: "email",
                    description: "Email address",
                    schema: .init(type: String.self),
                    isOptional: true   // Optional field
                ),
                DynamicGenerationSchema.Property(
                    name: "age",
                    description: "User age",
                    schema: .init(type: Int.self),
                    isOptional: false  // Required field
                ),
                DynamicGenerationSchema.Property(
                    name: "preferences",
                    description: "User preferences",
                    schema: .init(arrayOf: .init(type: String.self)),
                    isOptional: true   // Optional field
                )
            ]
        )
        
        // The model will:
        // 1. Always extract required fields
        // 2. Extract optional fields when available
        // 3. Omit optional fields if not found
        // 4. Handle missing required fields gracefully
        
        // You can filter properties dynamically:
        let requiredOnly = properties.filter { !$0.isOptional }
        """
    }
}

#Preview {
    NavigationStack {
        OptionalFieldsSchemaView()
    }
}
