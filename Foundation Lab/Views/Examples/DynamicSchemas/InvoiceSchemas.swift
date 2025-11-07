//
//  InvoiceSchemas.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
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

    private static func createDetailedLineItemProperties() -> [DynamicGenerationSchema.Property] {
        [
            DynamicGenerationSchema.Property(
                name: "itemNumber",
                description: "Line item number or identifier",
                schema: .init(type: Int.self)
            ),
            DynamicGenerationSchema.Property(
                name: "description",
                description: "Description of the goods or services",
                schema: .init(type: String.self)
            ),
            DynamicGenerationSchema.Property(
                name: "category",
                description: "Category or type of item",
                schema: .init(type: String.self)
            ),
            DynamicGenerationSchema.Property(
                name: "quantity",
                description: "Quantity of items",
                schema: .init(type: Double.self)
            ),
            DynamicGenerationSchema.Property(
                name: "unitOfMeasure",
                description: "Unit of measurement (e.g., each, hours, lbs)",
                schema: .init(type: String.self)
            ),
            DynamicGenerationSchema.Property(
                name: "unitPrice",
                description: "Price per unit",
                schema: .init(type: Double.self)
            ),
            DynamicGenerationSchema.Property(
                name: "lineTotal",
                description: "Total for this line item",
                schema: .init(type: Double.self)
            ),
            DynamicGenerationSchema.Property(
                name: "taxable",
                description: "Whether this item is taxable",
                schema: .init(type: Bool.self),
                isOptional: true
            )
        ]
    }

    private static func createLineItemsFocusProperties(
        detailedLineItemSchema: DynamicGenerationSchema
    ) -> [DynamicGenerationSchema.Property] {
        [
            DynamicGenerationSchema.Property(
                name: "invoiceNumber",
                description: "Invoice number this line items belong to",
                schema: .init(type: String.self)
            ),
            DynamicGenerationSchema.Property(
                name: "lineItems",
                description: "Array of detailed line items",
                schema: .init(arrayOf: detailedLineItemSchema)
            ),
            DynamicGenerationSchema.Property(
                name: "totalItems",
                description: "Total number of line items",
                schema: .init(type: Int.self)
            ),
            DynamicGenerationSchema.Property(
                name: "totalValue",
                description: "Total value of all line items",
                schema: .init(type: Double.self)
            )
        ]
    }

    static func createLineItemsSchema() -> DynamicGenerationSchema {
        let detailedLineItemSchema = DynamicGenerationSchema(
            name: "DetailedLineItem",
            description: "Detailed line item with full information",
            properties: createDetailedLineItemProperties()
        )

        return DynamicGenerationSchema(
            name: "LineItemsFocus",
            description: "Focus on line items with detailed information",
            properties: createLineItemsFocusProperties(detailedLineItemSchema: detailedLineItemSchema)
        )
    }
}
