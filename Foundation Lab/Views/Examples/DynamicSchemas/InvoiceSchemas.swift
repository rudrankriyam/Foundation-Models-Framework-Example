//
//  InvoiceSchemas.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import Foundation
import FoundationModels

/// Utility struct for creating various invoice processing schemas
struct InvoiceSchemas {

    private static func createAddressSchema() -> DynamicGenerationSchema {
        let companyProperty = DynamicGenerationSchema.Property(
            name: "company",
            description: "Company name",
            schema: .init(type: String.self)
        )
        let streetProperty = DynamicGenerationSchema.Property(
            name: "street",
            description: "Street address",
            schema: .init(type: String.self)
        )
        let cityProperty = DynamicGenerationSchema.Property(
            name: "city",
            description: "City name",
            schema: .init(type: String.self)
        )
        let stateProperty = DynamicGenerationSchema.Property(
            name: "state",
            description: "State or province",
            schema: .init(type: String.self)
        )
        let zipCodeProperty = DynamicGenerationSchema.Property(
            name: "zipCode",
            description: "ZIP or postal code",
            schema: .init(type: String.self)
        )
        let countryProperty = DynamicGenerationSchema.Property(
            name: "country",
            description: "Country name",
            schema: .init(type: String.self),
            isOptional: true
        )

        return DynamicGenerationSchema(
            name: "Address",
            description: "Address information",
            properties: [companyProperty, streetProperty, cityProperty, stateProperty, zipCodeProperty, countryProperty]
        )
    }

    private static func createLineItemSchema() -> DynamicGenerationSchema {
        let descriptionProperty = DynamicGenerationSchema.Property(
            name: "description",
            description: "Description of the goods or services",
            schema: .init(type: String.self)
        )
        let quantityProperty = DynamicGenerationSchema.Property(
            name: "quantity",
            description: "Quantity of items",
            schema: .init(type: Double.self)
        )
        let unitPriceProperty = DynamicGenerationSchema.Property(
            name: "unitPrice",
            description: "Price per unit",
            schema: .init(type: Double.self)
        )
        let amountProperty = DynamicGenerationSchema.Property(
            name: "amount",
            description: "Total amount for this line (quantity × unitPrice)",
            schema: .init(type: Double.self)
        )
        let taxRateProperty = DynamicGenerationSchema.Property(
            name: "taxRate",
            description: "Tax rate applied to this item",
            schema: .init(type: Double.self),
            isOptional: true
        )

        return DynamicGenerationSchema(
            name: "LineItem",
            description: "Individual invoice line item",
            properties: [descriptionProperty, quantityProperty, unitPriceProperty, amountProperty, taxRateProperty]
        )
    }

    private static func createInvoiceSchemaProperties(
        addressSchema: DynamicGenerationSchema,
        lineItemSchema: DynamicGenerationSchema
    ) -> [DynamicGenerationSchema.Property] {
        [
            DynamicGenerationSchema.Property(name: "invoiceNumber", description: "Invoice ID", schema: .init(type: String.self)),
            DynamicGenerationSchema.Property(name: "issueDate", description: "Issue date", schema: .init(type: String.self)),
            DynamicGenerationSchema.Property(name: "dueDate", description: "Due date", schema: .init(type: String.self)),
            DynamicGenerationSchema.Property(name: "fromAddress", description: "Seller address", schema: addressSchema),
            DynamicGenerationSchema.Property(name: "toAddress", description: "Buyer address", schema: addressSchema),
            DynamicGenerationSchema.Property(name: "lineItems", description: "Invoice items", schema: .init(arrayOf: lineItemSchema)),
            DynamicGenerationSchema.Property(name: "subtotal", description: "Pre-tax total", schema: .init(type: Double.self)),
            DynamicGenerationSchema.Property(name: "taxAmount", description: "Tax amount", schema: .init(type: Double.self)),
            DynamicGenerationSchema.Property(name: "taxRate", description: "Tax rate", schema: .init(type: Double.self)),
            DynamicGenerationSchema.Property(name: "total", description: "Total due", schema: .init(type: Double.self)),
            DynamicGenerationSchema.Property(name: "paymentTerms", description: "Payment terms", schema: .init(type: String.self)),
            DynamicGenerationSchema.Property(name: "notes", description: "Notes", schema: .init(type: String.self), isOptional: true)
        ]
    }

    static func createFullInvoiceSchema() -> DynamicGenerationSchema {
        let addressSchema = createAddressSchema()
        let lineItemSchema = createLineItemSchema()

        // Invoice schema
        return DynamicGenerationSchema(
            name: "Invoice",
            description: "Complete invoice with all details including addresses and line items",
            properties: createInvoiceSchemaProperties(addressSchema: addressSchema,
                                                    lineItemSchema: lineItemSchema)
        )
    }

    static func createSummarySchema() -> DynamicGenerationSchema {
        let invoiceNumberProperty = DynamicGenerationSchema.Property(
            name: "invoiceNumber",
            description: "Invoice number",
            schema: .init(type: String.self)
        )
        let totalAmountProperty = DynamicGenerationSchema.Property(
            name: "totalAmount",
            description: "Total amount due",
            schema: .init(type: Double.self)
        )
        let dueDateProperty = DynamicGenerationSchema.Property(
            name: "dueDate",
            description: "Payment due date",
            schema: .init(type: String.self)
        )
        let vendorNameProperty = DynamicGenerationSchema.Property(
            name: "vendorName",
            description: "Name of the vendor/company",
            schema: .init(type: String.self)
        )
        let customerNameProperty = DynamicGenerationSchema.Property(
            name: "customerName",
            description: "Name of the customer",
            schema: .init(type: String.self)
        )
        let itemCountProperty = DynamicGenerationSchema.Property(
            name: "itemCount",
            description: "Number of line items",
            schema: .init(type: Int.self)
        )

        return DynamicGenerationSchema(
            name: "InvoiceSummary",
            description: "Summary of key invoice information",
            properties: [invoiceNumberProperty, totalAmountProperty, dueDateProperty, vendorNameProperty, customerNameProperty, itemCountProperty]
        )
    }

    static func createLineItemsSchema() -> DynamicGenerationSchema {
        // Create detailed line item schema
        let itemNumberProperty = DynamicGenerationSchema.Property(
            name: "itemNumber",
            description: "Line item number or identifier",
            schema: .init(type: Int.self)
        )
        let descriptionProperty = DynamicGenerationSchema.Property(
            name: "description",
            description: "Description of the goods or services",
            schema: .init(type: String.self)
        )
        let categoryProperty = DynamicGenerationSchema.Property(
            name: "category",
            description: "Category or type of item",
            schema: .init(type: String.self)
        )
        let quantityProperty = DynamicGenerationSchema.Property(
            name: "quantity",
            description: "Quantity of items",
            schema: .init(type: Double.self)
        )
        let unitOfMeasureProperty = DynamicGenerationSchema.Property(
            name: "unitOfMeasure",
            description: "Unit of measurement (e.g., each, hours, lbs)",
            schema: .init(type: String.self)
        )
        let unitPriceProperty = DynamicGenerationSchema.Property(
            name: "unitPrice",
            description: "Price per unit",
            schema: .init(type: Double.self)
        )
        let lineTotalProperty = DynamicGenerationSchema.Property(
            name: "lineTotal",
            description: "Total for this line item",
            schema: .init(type: Double.self)
        )
        let taxableProperty = DynamicGenerationSchema.Property(
            name: "taxable",
            description: "Whether this item is taxable",
            schema: .init(type: Bool.self),
            isOptional: true
        )

        let detailedLineItemSchema = DynamicGenerationSchema(
            name: "DetailedLineItem",
            description: "Detailed line item with full information",
            properties: [itemNumberProperty, descriptionProperty, categoryProperty, quantityProperty,
                        unitOfMeasureProperty, unitPriceProperty, lineTotalProperty, taxableProperty]
        )

        // Create line items focus schema
        let invoiceNumberProperty = DynamicGenerationSchema.Property(
            name: "invoiceNumber",
            description: "Invoice number this line items belong to",
            schema: .init(type: String.self)
        )
        let lineItemsProperty = DynamicGenerationSchema.Property(
            name: "lineItems",
            description: "Array of detailed line items",
            schema: .init(arrayOf: detailedLineItemSchema)
        )
        let totalItemsProperty = DynamicGenerationSchema.Property(
            name: "totalItems",
            description: "Total number of line items",
            schema: .init(type: Int.self)
        )
        let totalValueProperty = DynamicGenerationSchema.Property(
            name: "totalValue",
            description: "Total value of all line items",
            schema: .init(type: Double.self)
        )

        return DynamicGenerationSchema(
            name: "LineItemsFocus",
            description: "Focus on line items with detailed information",
            properties: [invoiceNumberProperty, lineItemsProperty, totalItemsProperty, totalValueProperty]
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
