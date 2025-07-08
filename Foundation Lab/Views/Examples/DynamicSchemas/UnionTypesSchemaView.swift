//
//  UnionTypesSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct UnionTypesSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var contactInput = "Contact John Smith at john@example.com, works as a software engineer at Apple Inc."
    @State private var paymentInput = "Payment of $150.00 was made via credit card ending in 4242 on December 15, 2024"
    @State private var notificationInput = "System alert: Server maintenance scheduled for tonight at 11PM PST"
    @State private var selectedExample = 0
    
    private let examples = ["Contact", "Payment", "Notification"]
    
    var body: some View {
        ExampleViewBase(
            title: "Union Types (anyOf)",
            description: "Create schemas that can be one of several different types",
            defaultPrompt: contactInput,
            currentPrompt: .constant(currentInput),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { executor.reset() }
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
                
                // Input field
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: bindingForSelectedExample)
                        .font(.body)
                        .frame(minHeight: 60)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Schema visualization
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Schema Structure")
                        .font(.headline)
                    
                    Text(schemaDescription)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Extracted Data")
                            .font(.headline)
                        
                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .padding()
        }
    }
    
    private var currentInput: String {
        switch selectedExample {
        case 0: return contactInput
        case 1: return paymentInput
        case 2: return notificationInput
        default: return ""
        }
    }
    
    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $contactInput
        case 1: return $paymentInput
        case 2: return $notificationInput
        default: return .constant("")
        }
    }
    
    private var schemaDescription: String {
        switch selectedExample {
        case 0: return "Contact can be either:\n• Person (name, email, role)\n• Company (companyName, industry, contactEmail)"
        case 1: return "Payment can be:\n• Credit Card (amount, lastFourDigits, date)\n• Bank Transfer (amount, accountNumber, routingNumber)\n• Cryptocurrency (amount, cryptocurrency, walletAddress)"
        case 2: return "Notification can be:\n• System Alert (title, message, timestamp)\n• User Message (from, to, content, timestamp)\n• Error (code, message, stackTrace)"
        default: return ""
        }
    }
    
    private func runExample() async {
        let schema = createSchema(for: selectedExample)
        
        await executor.execute(
            withPrompt: "Extract the data from: \(currentInput)",
            schema: schema
        ) { result in
            """
            📊 Union Type Detection:
            The model automatically determined which variant matches the input.
            
            ✅ Extracted Data:
            \(result)
            
            💡 Note: anyOf schemas allow flexible data extraction when the exact type isn't known in advance.
            """
        }
    }
    
    private func createSchema(for index: Int) -> DynamicGenerationSchema {
        switch index {
        case 0: // Contact - Person or Company
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "Individual person contact",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Person's full name",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "email",
                        description: "Email address",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "role",
                        description: "Job title or role",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let companySchema = DynamicGenerationSchema(
                name: "Company",
                description: "Company contact",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "companyName",
                        description: "Company name",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "industry",
                        description: "Industry sector",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "contactEmail",
                        description: "Contact email",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            return DynamicGenerationSchema(
                name: "Contact",
                description: "Contact information - either person or company",
                anyOf: [personSchema, companySchema]
            )
            
        case 1: // Payment types - simplified for now
            // TODO: Implement credit card, bank transfer, crypto schemas
            return DynamicGenerationSchema(
                name: "Payment",
                description: "Payment information",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "amount",
                        description: "Payment amount",
                        schema: DynamicGenerationSchema(type: Double.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "method",
                        description: "Payment method",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "date",
                        description: "Payment date",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
        case 2: // Notification types - simplified for now
            // TODO: Implement system, user, error notification schemas
            return DynamicGenerationSchema(
                name: "Notification",
                description: "Notification information",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Notification type",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "message",
                        description: "Notification message",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "timestamp",
                        description: "When the notification occurred",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
        default:
            return DynamicGenerationSchema(
                name: "Default",
                properties: []
            )
        }
    }
    
    private var exampleCode: String {
        """
        // Creating anyOf schemas for union types
        
        // Define individual schemas
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            properties: [nameProperty, emailProperty]
        )
        
        let companySchema = DynamicGenerationSchema(
            name: "Company", 
            properties: [companyNameProperty, industryProperty]
        )
        
        // Create union schema
        let contactSchema = DynamicGenerationSchema(
            name: "Contact",
            description: "Either a person or company",
            anyOf: [personSchema, companySchema]
        )
        
        // The model will automatically determine which
        // schema variant best matches the input data
        """
    }
}

#Preview {
    NavigationStack {
        UnionTypesSchemaView()
    }
}