//
//  OptionalFieldsSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

@available(iOS 26.1, macOS 26.1, *)
struct OptionalFieldsSchemaView: View {
    enum ExampleType: String, CaseIterable, Identifiable {
        case userProfile = "User Profile"
        case productListing = "Product Listing"
        case eventDetails = "Event Details"
        
        var id: String { rawValue }
        
        var schemaName: String {
            switch self {
            case .userProfile: "UserProfile"
            case .productListing: "ProductListing"
            case .eventDetails: "EventDetails"
            }
        }
    }
    
    @State private var executor = ExampleExecutor()
    @State private var userProfileInput = "Sarah Johnson, 28 years old, from San Francisco. Works as a Product Manager. Enjoys hiking and photography."
    @State private var productListingInput = "MacBook Pro M3, starting at $1999. Available in Space Gray and Silver."
    @State private var eventInput = "Tech Conference 2024 on March 15. Registration required. Early bird discount available."
    @State private var selectedExample: ExampleType = .userProfile
    @State private var includeOptionalFields = true
    
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
            onReset: { selectedExample = .userProfile; includeOptionalFields = true }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(ExampleType.allCases) { example in
                        Text(example.rawValue).tag(example)
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
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text(field.name)
                                    .font(.system(.caption, design: .monospaced))
                                
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
        case .userProfile: $userProfileInput
        case .productListing: $productListingInput
        case .eventDetails: $eventInput
        }
    }
    
    private var currentInput: String {
        switch selectedExample {
        case .userProfile: userProfileInput
        case .productListing: productListingInput
        case .eventDetails: eventInput
        }
    }
    
    private struct SchemaField {
        let name: String
        let type: String
        let description: String
        let schema: DynamicGenerationSchema
        let optionality: DynamicGenerationSchema.Optionality
    }
    

    
    private var schemaFields: [SchemaField] {
        includeOptionalFields ? allSchemaFields : requiredFields
    }
    
    private var requiredFields: [SchemaField] {
        switch selectedExample {
        case .userProfile:
            return allSchemaFields.filter { ["name", "age"].contains($0.name) }
        case .productListing:
            return allSchemaFields.filter { ["name", "price"].contains($0.name) }
        case .eventDetails:
            return allSchemaFields.filter { ["title", "date"].contains($0.name) }
        }
    }
    
    private var allSchemaFields: [SchemaField] {
        switch selectedExample {
        case .userProfile:
            return [
                SchemaField(
                    name: "name",
                    type: "String",
                    description: "The person's full name",
                    schema: .init(type: String.self),
                    optionality: .required
                ),
                SchemaField(
                    name: "age",
                    type: "Int",
                    description: "The person's age",
                    schema: .init(type: Int.self),
                    optionality: .required
                ),
                SchemaField(
                    name: "location",
                    type: "String",
                    description: "Where the person is from or lives",
                    schema: .init(type: String.self),
                    optionality: .possiblyAbsent
                ),
                SchemaField(
                    name: "occupation",
                    type: "String",
                    description: "The person's job or profession",
                    schema: .init(type: String.self),
                    optionality: .possiblyAbsent
                ),
                SchemaField(
                    name: "bio",
                    type: "String",
                    description: "Brief biographical information",
                    schema: .init(type: String.self),
                    optionality: .possiblyNull
                ),
                SchemaField(
                    name: "interests",
                    type: "[String]",
                    description: "Hobbies or interests mentioned",
                    schema: .init(arrayOf: .init(type: String.self)),
                    optionality: .possiblyAbsent
                )
            ]
            
        case .productListing:
            return [
                SchemaField(
                    name: "name",
                    type: "String",
                    description: "Product name",
                    schema: .init(type: String.self),
                    optionality: .required
                ),
                SchemaField(
                    name: "price",
                    type: "Float",
                    description: "Product price",
                    schema: .init(type: Float.self),
                    optionality: .required
                ),
                SchemaField(
                    name: "description",
                    type: "String",
                    description: "Product description",
                    schema: .init(type: String.self),
                    optionality: .possiblyAbsent
                ),
                SchemaField(
                    name: "colors",
                    type: "[String]",
                    description: "Available colors",
                    schema: .init(arrayOf: .init(type: String.self)),
                    optionality: .possiblyAbsent
                ),
                SchemaField(
                    name: "inStock",
                    type: "Bool",
                    description: "Whether the product is in stock",
                    schema: .init(type: Bool.self),
                    optionality: .possiblyNull
                ),
                SchemaField(
                    name: "discount",
                    type: "Float",
                    description: "Discount percentage if any",
                    schema: .init(type: Float.self),
                    optionality: .possiblyNull
                )
            ]
            
        case .eventDetails:
            return [
                SchemaField(
                    name: "title",
                    type: "String",
                    description: "Event title",
                    schema: .init(type: String.self),
                    optionality: .required
                ),
                SchemaField(
                    name: "date",
                    type: "String",
                    description: "Event date",
                    schema: .init(type: String.self),
                    optionality: .required
                ),
                SchemaField(
                    name: "venue",
                    type: "String",
                    description: "Event location or venue",
                    schema: .init(type: String.self),
                    optionality: .possiblyAbsent
                ),
                SchemaField(
                    name: "capacity",
                    type: "Int",
                    description: "Maximum attendees",
                    schema: .init(type: Int.self),
                    optionality: .possiblyAbsent
                ),
                SchemaField(
                    name: "registration",
                    type: "String",
                    description: "Registration requirements",
                    schema: .init(type: String.self),
                    optionality: .possiblyNull
                ),
                SchemaField(
                    name: "earlyBird",
                    type: "Bool",
                    description: "Early bird discount available",
                    schema: .init(type: Bool.self),
                    optionality: .possiblyNull
                )
            ]
        }
    }
    
    private func runExample() async {
        await executor.execute {
            let schema = try createSchema()
            let session = LanguageModelSession()
            
            let prompt = includeOptionalFields ?
            "Extract all available information from this text, including optional details:" :
            "Extract only the essential required information from this text:"
            
            let response = try await session.respond(
                to: Prompt("\(prompt)\n\n\(currentInput)"),
                schema: schema,
                options: .init(temperature: 0.1)
            )
            
            let properties: [String: GeneratedContent]
            switch response.content.kind {
            case .structure(let props, _):
                properties = props
            default:
                properties = [:]
            }
            
            var extractedFields: [(SchemaField, String)] = []
            
            // Check which fields were extracted
            for field in schemaFields {
                if let value = properties[field.name] {
                    let valueStr = formatFieldValue(value)
                    extractedFields.append((field, valueStr))
                }
            }
            
            return """
            📝 Input:
            \(currentInput)
            
            🔍 Extraction Mode: \(includeOptionalFields ? "All Fields" : "Required Only")
            
            📊 Extracted Fields:
            \(formatExtractedFields(extractedFields))
            
            ✅ Schema Validation:
            • Total fields: \(schemaFields.count)
            • Fields extracted: \(extractedFields.count)
            """
        }
    }
    
    private func createSchema() throws -> GenerationSchema {
        let properties = schemaFields.map { field in
            DynamicGenerationSchema.Property(
                name: field.name,
                description: field.description,
                schema: field.schema,
                optionality: field.optionality
            )
        }
        
        let schemaName = selectedExample.schemaName
        let schema = DynamicGenerationSchema(
            name: schemaName,
            description: "Extract \(includeOptionalFields ? "all" : "required") information",
            properties: properties
        )
        
        return try GenerationSchema(root: schema, dependencies: [])
    }
    
    private func formatFieldValue(_ content: GeneratedContent) -> String {
        switch content.kind {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return bool ? "true" : "false"
        case .array(let elements):
            let items = elements.compactMap { element in
                switch element.kind {
                case .string(let str):
                    return str
                default:
                    return nil
                }
            }
            return "[\(items.joined(separator: ", "))]"
        case .null:
            return "null"
        case .structure(_, _):
            return "<object>"
        @unknown default:
            return "<unknown>"
        }
    }
    
    private func formatExtractedFields(_ fields: [(SchemaField, String)]) -> String {
        fields.map { entry in
            let (field, value) = entry
            return "• \(field.name): \(value)"
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
                    optionality: .required
                ),
                DynamicGenerationSchema.Property(
                    name: "email",
                    description: "Email address",
                    schema: .init(type: String.self),
                    optionality: .possiblyAbsent
                ),
                DynamicGenerationSchema.Property(
                    name: "age",
                    description: "User age",
                    schema: .init(type: Int.self),
                    optionality: .required
                ),
                DynamicGenerationSchema.Property(
                    name: "preferences",
                    description: "User preferences",
                    schema: .init(arrayOf: .init(type: String.self)),
                    optionality: .possiblyNull
                )
            ]
        )
        
        // Optionality options (iOS 26.1+):
        // • .required: model must emit the field
        // • .possiblyAbsent: field may be omitted entirely
        // • .possiblyNull: field may appear with a null value
        
        // Use the optionality parameter to control field requirements
        let response = try await session.respond(
            to: "Extract user information",
            schema: GenerationSchema(root: userSchema, dependencies: [])
        )
        """
    }
}

#Preview {
    if #available(iOS 26.1, macOS 26.1, *) {
        NavigationStack {
            OptionalFieldsSchemaView()
        }
    } else {
        Text("Requires iOS/macOS 26.1")
    }
}
