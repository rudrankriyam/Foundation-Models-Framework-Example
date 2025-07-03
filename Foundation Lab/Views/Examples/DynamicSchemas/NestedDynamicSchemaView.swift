//
//  NestedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct NestedDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var companyInput = """
    Apple Inc. is headquartered in Cupertino, California. The CEO is Tim Cook who has been leading \
    the company since 2011. Apple has several major departments including Hardware Engineering led by \
    John Ternus, Software Engineering led by Craig Federighi, and Services led by Eddy Cue. \
    The company was founded in 1976 and has over 160,000 employees worldwide.
    """
    
    @State private var orderInput = """
    Order #12345 was placed on January 15, 2024 by Jane Smith. She ordered 2 iPhone 15 Pro units \
    at $999 each and 1 MacBook Pro 14" for $1999. The items should be shipped to 123 Main St, \
    San Francisco, CA 94105. Payment was made with Visa ending in 4242. Express shipping was selected.
    """
    
    @State private var eventInput = """
    The AI Conference 2024 will be held at the Moscone Center in San Francisco from March 15-17. \
    The keynote speaker is Dr. Sarah Johnson from Stanford University who will talk about \
    "The Future of Language Models". Other sessions include "Computer Vision Advances" by Prof. Michael Chen \
    and "Ethics in AI" by Dr. Emily Rodriguez. Registration costs $599 for early bird tickets.
    """
    
    @State private var selectedExample = 0
    @State private var nestingDepth = 2
    
    private let examples = ["Company Structure", "Order Details", "Event Information"]
    
    var body: some View {
        ExampleViewBase(
            title: "Nested Objects",
            description: "Create complex nested object structures with multiple levels",
            defaultPrompt: companyInput,
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
                
                // Nesting visualization
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Schema Structure")
                        .font(.headline)
                    
                    Text(schemaVisualization)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Input text
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: bindingForSelectedExample)
                        .font(.body)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                HStack {
                    Button("Extract Nested Data") {
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
        case 0: return $companyInput
        case 1: return $orderInput
        default: return $eventInput
        }
    }
    
    private var currentInput: String {
        switch selectedExample {
        case 0: return companyInput
        case 1: return orderInput
        default: return eventInput
        }
    }
    
    private var schemaVisualization: String {
        switch selectedExample {
        case 0:
            return """
            Company
            ├── name: String
            ├── headquarters: Location
            │   ├── city: String
            │   └── state: String
            ├── ceo: Person
            │   ├── name: String
            │   └── startYear: Int
            └── departments: [Department]
                ├── name: String
                └── head: String
            """
        case 1:
            return """
            Order
            ├── orderNumber: String
            ├── date: String
            ├── customer: Customer
            │   └── name: String
            ├── items: [OrderItem]
            │   ├── name: String
            │   ├── quantity: Int
            │   └── price: Float
            ├── shipping: ShippingInfo
            │   └── address: Address
            └── payment: PaymentInfo
            """
        default:
            return """
            Event
            ├── name: String
            ├── venue: Venue
            │   ├── name: String
            │   └── location: String
            ├── dates: DateRange
            │   ├── start: String
            │   └── end: String
            └── sessions: [Session]
                ├── title: String
                └── speaker: Speaker
            """
        }
    }
    
    private func runExample() async {
        await executor.execute {
            let schema = try createSchema(for: selectedExample)
            let session = LanguageModelSession()
            
            let prompt = """
            Extract the structured information from this text:
            
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
            
            📊 Extracted Nested Structure:
            \(formatNestedContent(response.content, indent: 0))
            
            🔍 Nesting Levels Found: \(countNestingLevels(response.content))
            """
        }
    }
    
    private func createSchema(for index: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            // Company structure with nested departments and people
            let locationSchema = DynamicGenerationSchema(
                name: "Location",
                description: "A geographic location",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "city",
                        description: "City name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "state",
                        description: "State or region",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "Information about a person",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Person's full name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "startYear",
                        description: "Year they started",
                        schema: .init(type: Int.self),
                        isOptional: true
                    )
                ]
            )
            
            let departmentSchema = DynamicGenerationSchema(
                name: "Department",
                description: "Company department",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Department name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "head",
                        description: "Department head name",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let companySchema = DynamicGenerationSchema(
                name: "Company",
                description: "Company information",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Company name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "headquarters",
                        description: "Company headquarters location",
                        schema: locationSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "ceo",
                        description: "Chief Executive Officer",
                        schema: personSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "foundedYear",
                        description: "Year company was founded",
                        schema: .init(type: Int.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "employeeCount",
                        description: "Number of employees",
                        schema: .init(type: Int.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "departments",
                        description: "List of departments",
                        schema: .init(arrayOf: departmentSchema),
                        isOptional: true
                    )
                ]
            )
            
            return try GenerationSchema(
                root: companySchema,
                dependencies: [locationSchema, personSchema, departmentSchema]
            )
            
        case 1:
            // Order with nested customer, items, and shipping
            let customerSchema = DynamicGenerationSchema(
                name: "Customer",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        schema: .init(type: String.self)
                    )
                ]
            )
            
            let orderItemSchema = DynamicGenerationSchema(
                name: "OrderItem",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Item name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "quantity",
                        schema: .init(type: Int.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "price",
                        schema: .init(type: Float.self)
                    )
                ]
            )
            
            let addressSchema = DynamicGenerationSchema(
                name: "Address",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "street",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "city",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "state",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "zip",
                        schema: .init(type: String.self)
                    )
                ]
            )
            
            let shippingSchema = DynamicGenerationSchema(
                name: "ShippingInfo",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "address",
                        schema: addressSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "method",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let paymentSchema = DynamicGenerationSchema(
                name: "PaymentInfo",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "method",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "lastFour",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let orderSchema = DynamicGenerationSchema(
                name: "Order",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "orderNumber",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "date",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "customer",
                        schema: customerSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "items",
                        schema: .init(arrayOf: orderItemSchema)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "shipping",
                        schema: shippingSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "payment",
                        schema: paymentSchema
                    )
                ]
            )
            
            return try GenerationSchema(
                root: orderSchema,
                dependencies: [customerSchema, orderItemSchema, addressSchema, shippingSchema, paymentSchema]
            )
            
        default:
            // Event with nested venue and sessions
            let venueSchema = DynamicGenerationSchema(
                name: "Venue",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "location",
                        schema: .init(type: String.self)
                    )
                ]
            )
            
            let dateRangeSchema = DynamicGenerationSchema(
                name: "DateRange",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "start",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "end",
                        schema: .init(type: String.self)
                    )
                ]
            )
            
            let speakerSchema = DynamicGenerationSchema(
                name: "Speaker",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "affiliation",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let sessionSchema = DynamicGenerationSchema(
                name: "Session",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "title",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "speaker",
                        schema: speakerSchema
                    )
                ]
            )
            
            let eventSchema = DynamicGenerationSchema(
                name: "Event",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "venue",
                        schema: venueSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "dates",
                        schema: dateRangeSchema
                    ),
                    DynamicGenerationSchema.Property(
                        name: "sessions",
                        schema: .init(arrayOf: sessionSchema),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "registrationPrice",
                        schema: .init(type: Float.self),
                        isOptional: true
                    )
                ]
            )
            
            return try GenerationSchema(
                root: eventSchema,
                dependencies: [venueSchema, dateRangeSchema, speakerSchema, sessionSchema]
            )
        }
    }
    
    private func formatNestedContent(_ content: GeneratedContent, indent: Int) -> String {
        let indentString = String(repeating: "  ", count: indent)
        var result = ""
        
        do {
            if let properties = try? content.properties() {
                for (key, value) in properties {
                    result += "\n\(indentString)\(key): "
                    
                    if let _ = try? value.properties() {
                        // Nested object
                        result += formatNestedContent(value, indent: indent + 1)
                    } else if let elements = try? value.elements() {
                        // Array
                        result += "["
                        for (i, element) in elements.enumerated() {
                            result += formatNestedContent(element, indent: indent + 1)
                            if i < elements.count - 1 {
                                result += ","
                            }
                        }
                        result += "\n\(indentString)]"
                    } else if let stringValue = try? value.value(String.self) {
                        result += "\"\(stringValue)\""
                    } else if let intValue = try? value.value(Int.self) {
                        result += String(intValue)
                    } else if let floatValue = try? value.value(Float.self) {
                        result += String(format: "%.2f", floatValue)
                    }
                }
            } else if let stringValue = try? content.value(String.self) {
                result += "\"\(stringValue)\""
            }
        } catch {
            result += "error"
        }
        
        return result
    }
    
    private func countNestingLevels(_ content: GeneratedContent, currentLevel: Int = 0) -> Int {
        var maxLevel = currentLevel
        
        if let properties = try? content.properties() {
            for (_, value) in properties {
                if let _ = try? value.properties() {
                    maxLevel = max(maxLevel, countNestingLevels(value, currentLevel: currentLevel + 1))
                } else if let elements = try? value.elements() {
                    for element in elements {
                        maxLevel = max(maxLevel, countNestingLevels(element, currentLevel: currentLevel + 1))
                    }
                }
            }
        }
        
        return maxLevel
    }
    
    private var exampleCode: String {
        """
        // Creating deeply nested schemas
        let addressSchema = DynamicGenerationSchema(
            name: "Address",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "street",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "city",
                    schema: .init(type: String.self)
                )
            ]
        )
        
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "address",
                    schema: addressSchema  // Nested object
                )
            ]
        )
        
        // Arrays of nested objects
        let teamSchema = DynamicGenerationSchema(
            name: "Team",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "members",
                    schema: .init(arrayOf: personSchema)
                )
            ]
        )
        
        // Register all schemas as dependencies
        let schema = try GenerationSchema(
            root: teamSchema,
            dependencies: [addressSchema, personSchema]
        )
        """
    }
}

#Preview {
    NavigationStack {
        NestedDynamicSchemaView()
    }
}