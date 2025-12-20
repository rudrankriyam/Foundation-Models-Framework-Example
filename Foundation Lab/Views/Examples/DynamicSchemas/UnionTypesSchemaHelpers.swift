//
//  UnionTypesSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension UnionTypesSchemaView {
    func schemaDescription(for index: Int) -> String {
        switch index {
        case 0: return "Contact can be either:\n• Person (name, email, role)\n• Company (companyName, industry, contactEmail)"
        case 1:
            return """
                Payment can be:
                • Credit Card (amount with min $0.01, lastFourDigits matching \\d{4}, \
                cardType from list, date)
                • Bank Transfer (amount with min $0.01, accountNumber \\d{4}, \
                routingNumber \\d{9}, date)
                • Cryptocurrency (amount with min $0.01, cryptocurrency from \
                Bitcoin/Ethereum/USDT/USDC, walletAddress, date)
                """
        case 2:
            return """
                Notification can be:
                • System Alert (severity: info/warning/error/critical, title, message, \
                ISO timestamp)
                • User Message (from, to, content, priority: low/normal/high/urgent, \
                timestamp)
                • Error (code matching [A-Z]{3}-\\d{3,4}, message, stackTrace, timestamp)
                """
        default: return ""
        }
    }

    func createContactSchema() -> DynamicGenerationSchema {
        let personSchema = DynamicSchemaHelpers.schema(
            "Person",
            description: "Individual person contact",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Person's full name"
                ),
                DynamicGenerationSchema.Property(
                    name: "email",
                    description: "Email address",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)]
                    )
                ),
                DynamicSchemaHelpers.typedProperty(
                    "role",
                    type: String.self,
                    description: "Job title or role",
                    isOptional: true
                )
            ]
        )

        let companySchema = DynamicSchemaHelpers.schema(
            "Company",
            description: "Company contact",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "companyName",
                    type: String.self,
                    description: "Company name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "industry",
                    type: String.self,
                    description: "Industry sector",
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
    }

    func createCreditCardSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "CreditCard",
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
                DynamicSchemaHelpers.typedProperty(
                    "date",
                    type: String.self,
                    description: "Payment date"
                )
            ]
        )
    }

    func createBankTransferSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "BankTransfer",
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
                DynamicSchemaHelpers.typedProperty(
                    "date",
                    type: String.self,
                    description: "Payment date"
                )
            ]
        )
    }

    func createCryptoSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Cryptocurrency",
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
                DynamicSchemaHelpers.typedProperty(
                    "walletAddress",
                    type: String.self,
                    description: "Wallet address (partial)",
                    isOptional: true
                ),
                DynamicSchemaHelpers.typedProperty(
                    "date",
                    type: String.self,
                    description: "Payment date"
                )
            ]
        )
    }

    func createPaymentSchema() -> DynamicGenerationSchema {
        let creditCardSchema = createCreditCardSchema()
        let bankTransferSchema = createBankTransferSchema()
        let cryptoSchema = createCryptoSchema()

        return DynamicGenerationSchema(
            name: "Payment",
            description: "Payment information - credit card, bank transfer, or cryptocurrency",
            anyOf: [creditCardSchema, bankTransferSchema, cryptoSchema]
        )
    }

    func createSystemAlertSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "SystemAlert",
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
                DynamicSchemaHelpers.typedProperty(
                    "title",
                    type: String.self,
                    description: "Alert title"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "message",
                    type: String.self,
                    description: "Alert message"
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
    }

    func createUserMessageSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "UserMessage",
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
                DynamicSchemaHelpers.typedProperty(
                    "from",
                    type: String.self,
                    description: "Sender name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "to",
                    type: String.self,
                    description: "Recipient name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "content",
                    type: String.self,
                    description: "Message content"
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
                DynamicSchemaHelpers.typedProperty(
                    "timestamp",
                    type: String.self,
                    description: "Message timestamp",
                    isOptional: true
                )
            ]
        )
    }

    func createErrorNotificationSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "ErrorNotification",
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
                DynamicSchemaHelpers.typedProperty(
                    "message",
                    type: String.self,
                    description: "Error message"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "stackTrace",
                    type: String.self,
                    description: "Stack trace if available",
                    isOptional: true
                ),
                DynamicSchemaHelpers.typedProperty(
                    "timestamp",
                    type: String.self,
                    description: "Error timestamp",
                    isOptional: true
                )
            ]
        )
    }

    func createNotificationSchema() -> DynamicGenerationSchema {
        let systemAlertSchema = createSystemAlertSchema()
        let userMessageSchema = createUserMessageSchema()
        let errorNotificationSchema = createErrorNotificationSchema()

        return DynamicGenerationSchema(
            name: "Notification",
            description: "Notification - system alert, user message, or error",
            anyOf: [systemAlertSchema, userMessageSchema, errorNotificationSchema]
        )
    }

    var exampleCode: String {
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
