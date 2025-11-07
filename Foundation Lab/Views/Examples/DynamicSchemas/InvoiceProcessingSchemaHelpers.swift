//
//  InvoiceProcessingSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension InvoiceProcessingSchemaView {
    var exampleCode: String {
        """
        // Complex invoice processing with nested schemas

        // Define reusable address schema
        let addressSchema = DynamicGenerationSchema(
            name: "Address",
            type: .object,
            properties: [
                "company": .init(type: .string),
                "street": .init(type: .string),
                "city": .init(type: .string),
                "state": .init(type: .string),
                "postalCode": .init(type: .string)
            ]
        )

        // Line item schema with calculations
        let lineItemSchema = DynamicGenerationSchema(
            name: "LineItem",
            type: .object,
            properties: [
                "description": .init(type: .string),
                "quantity": .init(type: .number),
                "unitPrice": .init(type: .number),
                "amount": .init(type: .number)
            ]
        )

        // Main invoice schema composition
        let invoiceSchema = DynamicGenerationSchema(
            name: "Invoice",
            type: .object,
            properties: [
                "invoiceNumber": .init(type: .string),
                "seller": addressSchema.asProperty(),
                "buyer": addressSchema.asProperty(),
                "lineItems": .init(
                    type: .array,
                    items: lineItemSchema
                ),
                "subtotal": .init(type: .number),
                "tax": .init(type: .object, properties: [
                    "rate": .init(type: .number),
                    "amount": .init(type: .number)
                ]),
                "totalAmount": .init(type: .number)
            ],
            requiredProperties: ["invoiceNumber", "totalAmount"]
        )

        // Extract and validate
        let invoice = try await model.respond(
            withSchema: invoiceSchema,
            to: SystemPrompt(text: invoiceText)
        )
        """
    }
}
