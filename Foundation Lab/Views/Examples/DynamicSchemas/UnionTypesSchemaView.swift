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
            currentPrompt: bindingForSelectedExample,
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
        case 1: return "Payment can be:\n• Credit Card (amount with min $0.01, lastFourDigits matching \\d{4}, cardType from list, date)\n• Bank Transfer (amount with min $0.01, accountNumber \\d{4}, routingNumber \\d{9}, date)\n• Cryptocurrency (amount with min $0.01, cryptocurrency from Bitcoin/Ethereum/USDT/USDC, walletAddress, date)"
        case 2: return "Notification can be:\n• System Alert (severity: info/warning/error/critical, title, message, ISO timestamp)\n• User Message (from, to, content, priority: low/normal/high/urgent, timestamp)\n• Error (code matching [A-Z]{3}-\\d{3,4}, message, stackTrace, timestamp)"
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
            Union Type Detection:
            The model automatically determined which variant matches the input.
            
            Extracted Data:
            \(result)
            
            Note: anyOf schemas allow flexible data extraction when the exact type isn't known in advance.
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
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)]
                        )
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
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)]
                        ),
                        isOptional: true
                    )
                ]
            )
            
            return DynamicGenerationSchema(
                name: "Contact",
                description: "Contact information - either person or company",
                anyOf: [personSchema, companySchema]
            )
            
        case 1: // Payment types with union schema
            let creditCardSchema = DynamicGenerationSchema(
                name: "CreditCard",
                description: "Credit card payment",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Payment type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.constant("credit_card")]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "amount",
                        description: "Payment amount in dollars",
                        schema: DynamicGenerationSchema(
                            type: Double.self,
                            guides: [.minimum(0.01)]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "lastFourDigits",
                        description: "Last four digits of card",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^\d{4}$/)]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "cardType",
                        description: "Card type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.anyOf(["Visa", "MasterCard", "Amex", "Discover"])]
                        ),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "date",
                        description: "Payment date",
                        schema: DynamicGenerationSchema(type: String.self)
                    )
                ]
            )
            
            let bankTransferSchema = DynamicGenerationSchema(
                name: "BankTransfer",
                description: "Bank transfer payment",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Payment type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.constant("bank_transfer")]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "amount",
                        description: "Payment amount in dollars",
                        schema: DynamicGenerationSchema(
                            type: Double.self,
                            guides: [.minimum(0.01)]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "accountNumber",
                        description: "Bank account last 4 digits",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^\d{4}$/)]
                        ),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "routingNumber",
                        description: "Bank routing number",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^\d{9}$/)]
                        ),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "date",
                        description: "Payment date",
                        schema: DynamicGenerationSchema(type: String.self)
                    )
                ]
            )
            
            let cryptoSchema = DynamicGenerationSchema(
                name: "Cryptocurrency",
                description: "Cryptocurrency payment",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Payment type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.constant("cryptocurrency")]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "amount",
                        description: "Payment amount in USD equivalent",
                        schema: DynamicGenerationSchema(
                            type: Double.self,
                            guides: [.minimum(0.01)]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "cryptocurrency",
                        description: "Cryptocurrency type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.anyOf(["Bitcoin", "Ethereum", "USDT", "USDC"])]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "walletAddress",
                        description: "Wallet address (partial)",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "date",
                        description: "Payment date",
                        schema: DynamicGenerationSchema(type: String.self)
                    )
                ]
            )
            
            return DynamicGenerationSchema(
                name: "Payment",
                description: "Payment information - credit card, bank transfer, or cryptocurrency",
                anyOf: [creditCardSchema, bankTransferSchema, cryptoSchema]
            )
            
        case 2: // Notification types with union schema
            let systemAlertSchema = DynamicGenerationSchema(
                name: "SystemAlert",
                description: "System-generated alert",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Alert type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.constant("system")]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "severity",
                        description: "Alert severity",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.anyOf(["info", "warning", "error", "critical"])]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "title",
                        description: "Alert title",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "message",
                        description: "Alert message",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "timestamp",
                        description: "ISO 8601 timestamp",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)]
                        ),
                        isOptional: true
                    )
                ]
            )
            
            let userMessageSchema = DynamicGenerationSchema(
                name: "UserMessage",
                description: "User-to-user message",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Message type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.constant("user_message")]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "from",
                        description: "Sender name",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "to",
                        description: "Recipient name",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "content",
                        description: "Message content",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "priority",
                        description: "Message priority",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.anyOf(["low", "normal", "high", "urgent"])]
                        ),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "timestamp",
                        description: "Message timestamp",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let errorNotificationSchema = DynamicGenerationSchema(
                name: "ErrorNotification",
                description: "Error notification",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "type",
                        description: "Notification type",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.constant("error")]
                        )
                    ),
                    DynamicGenerationSchema.Property(
                        name: "code",
                        description: "Error code",
                        schema: DynamicGenerationSchema(
                            type: String.self,
                            guides: [.pattern(/^[A-Z]{3}-\d{3,4}$/)]
                        ),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "message",
                        description: "Error message",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "stackTrace",
                        description: "Stack trace if available",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "timestamp",
                        description: "Error timestamp",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            return DynamicGenerationSchema(
                name: "Notification",
                description: "Notification - system alert, user message, or error",
                anyOf: [systemAlertSchema, userMessageSchema, errorNotificationSchema]
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