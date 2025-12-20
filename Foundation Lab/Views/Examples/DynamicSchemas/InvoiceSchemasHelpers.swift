//
//  InvoiceSchemasHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension InvoiceSchemas {
    static func createSummarySchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "InvoiceSummary",
            description: "Summary of key invoice information",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "invoiceNumber",
                    type: String.self,
                    description: "Invoice number"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "totalAmount",
                    type: Double.self,
                    description: "Total amount due"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "dueDate",
                    type: String.self,
                    description: "Payment due date"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "vendorName",
                    type: String.self,
                    description: "Name of the vendor/company"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "customerName",
                    type: String.self,
                    description: "Name of the customer"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "itemCount",
                    type: Int.self,
                    description: "Number of line items"
                )
            ]
        )
    }

    static func validateInvoiceTotals(_ invoice: [String: Any]) -> String {
        var issues = [String]()

        // Check if we have the necessary data
        guard let lineItems = invoice["lineItems"] as? [[String: Any]],
              let subtotal = invoice["subtotal"] as? Double,
              let taxAmount = invoice["taxAmount"] as? Double,
              let taxRate = invoice["taxRate"] as? Double,
              let total = invoice["total"] as? Double else {
            return "Missing required fields for validation"
        }

        // Calculate expected subtotal from line items
        var calculatedSubtotal = 0.0
        for item in lineItems {
            if let amount = item["amount"] as? Double {
                calculatedSubtotal += amount
            }
        }

        // Check subtotal accuracy
        let subtotalDifference = abs(calculatedSubtotal - subtotal)
        if subtotalDifference > 0.01 {
            issues.append(String(format: "Subtotal mismatch: calculated %.2f, extracted %.2f",
                               calculatedSubtotal, subtotal))
        }

        // Check tax calculation
        let expectedTax = subtotal * taxRate
        let taxDifference = abs(expectedTax - taxAmount)
        if taxDifference > 0.01 {
            issues.append(String(format: "Tax calculation error: expected %.2f, got %.2f",
                               expectedTax, taxAmount))
        }

        // Check total calculation
        let expectedTotal = subtotal + taxAmount
        let totalDifference = abs(expectedTotal - total)
        if totalDifference > 0.01 {
            issues.append(String(format: "Total calculation error: expected %.2f, got %.2f",
                               expectedTotal, total))
        }

        return issues.isEmpty ? "All calculations are correct" : issues.joined(separator: "; ")
    }
}
