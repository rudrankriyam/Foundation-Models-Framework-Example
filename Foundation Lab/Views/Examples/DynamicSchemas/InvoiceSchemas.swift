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
    static func createFullInvoiceSchema() -> DynamicGenerationSchema {
        let addressSchema = createAddressSchema()
        let lineItemSchema = createLineItemSchema()

        return DynamicGenerationSchema(
            name: "Invoice",
            description: "Complete invoice with all details including addresses and line items",
            properties: createInvoiceSchemaProperties(
                addressSchema: addressSchema,
                lineItemSchema: lineItemSchema
            )
        )
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

private extension InvoiceSchemas {
    static func createAddressSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Address",
            description: "Address information",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "company",
                    type: String.self,
                    description: "Company name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "street",
                    type: String.self,
                    description: "Street address"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "city",
                    type: String.self,
                    description: "City name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "state",
                    type: String.self,
                    description: "State or province"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "zipCode",
                    type: String.self,
                    description: "ZIP or postal code"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "country",
                    type: String.self,
                    description: "Country name",
                    isOptional: true
                )
            ]
        )
    }

    static func createLineItemSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "LineItem",
            description: "Individual invoice line item",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "description",
                    type: String.self,
                    description: "Description of the goods or services"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "quantity",
                    type: Double.self,
                    description: "Quantity of items"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "unitPrice",
                    type: Double.self,
                    description: "Price per unit"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "amount",
                    type: Double.self,
                    description: "Total amount for this line (quantity × unitPrice)"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "taxRate",
                    type: Double.self,
                    description: "Tax rate applied to this item",
                    isOptional: true
                )
            ]
        )
    }

    static func createInvoiceSchemaProperties(
        addressSchema: DynamicGenerationSchema,
        lineItemSchema: DynamicGenerationSchema
    ) -> [DynamicGenerationSchema.Property] {
        createInvoiceHeaderProperties()
        + createInvoicePartyProperties(addressSchema: addressSchema)
        + createInvoiceTotalsProperties(lineItemSchema: lineItemSchema)
    }

    static func createInvoiceHeaderProperties() -> [DynamicGenerationSchema.Property] {
        [
            DynamicSchemaHelpers.typedProperty(
                "invoiceNumber",
                type: String.self,
                description: "Invoice ID"
            ),
            DynamicSchemaHelpers.typedProperty(
                "issueDate",
                type: String.self,
                description: "Issue date"
            ),
            DynamicSchemaHelpers.typedProperty(
                "dueDate",
                type: String.self,
                description: "Due date"
            )
        ]
    }

    static func createInvoicePartyProperties(
        addressSchema: DynamicGenerationSchema
    ) -> [DynamicGenerationSchema.Property] {
        [
            DynamicSchemaHelpers.nestedProperty(
                "fromAddress",
                schema: addressSchema,
                description: "Seller address"
            ),
            DynamicSchemaHelpers.nestedProperty(
                "toAddress",
                schema: addressSchema,
                description: "Buyer address"
            )
        ]
    }

    static func createInvoiceTotalsProperties(
        lineItemSchema: DynamicGenerationSchema
    ) -> [DynamicGenerationSchema.Property] {
        [
            DynamicSchemaHelpers.arrayProperty(
                "lineItems",
                elementSchema: lineItemSchema,
                description: "Invoice items"
            ),
            DynamicSchemaHelpers.typedProperty(
                "subtotal",
                type: Double.self,
                description: "Pre-tax total"
            ),
            DynamicSchemaHelpers.typedProperty(
                "taxAmount",
                type: Double.self,
                description: "Tax amount"
            ),
            DynamicSchemaHelpers.typedProperty(
                "taxRate",
                type: Double.self,
                description: "Tax rate"
            ),
            DynamicSchemaHelpers.typedProperty(
                "total",
                type: Double.self,
                description: "Total due"
            ),
            DynamicSchemaHelpers.typedProperty(
                "paymentTerms",
                type: String.self,
                description: "Payment terms"
            ),
            DynamicSchemaHelpers.typedProperty(
                "notes",
                type: String.self,
                description: "Notes",
                isOptional: true
            )
        ]
    }

    static func createDetailedLineItemProperties() -> [DynamicGenerationSchema.Property] {
        [
            DynamicSchemaHelpers.typedProperty(
                "itemNumber",
                type: Int.self,
                description: "Line item number or identifier"
            ),
            DynamicSchemaHelpers.typedProperty(
                "description",
                type: String.self,
                description: "Description of the goods or services"
            ),
            DynamicSchemaHelpers.typedProperty(
                "category",
                type: String.self,
                description: "Category or type of item"
            ),
            DynamicSchemaHelpers.typedProperty(
                "quantity",
                type: Double.self,
                description: "Quantity of items"
            ),
            DynamicSchemaHelpers.typedProperty(
                "unitOfMeasure",
                type: String.self,
                description: "Unit of measurement (e.g., each, hours, lbs)"
            ),
            DynamicSchemaHelpers.typedProperty(
                "unitPrice",
                type: Double.self,
                description: "Price per unit"
            ),
            DynamicSchemaHelpers.typedProperty(
                "lineTotal",
                type: Double.self,
                description: "Total for this line item"
            ),
            DynamicSchemaHelpers.typedProperty(
                "taxable",
                type: Bool.self,
                description: "Whether this item is taxable",
                isOptional: true
            )
        ]
    }

    static func createLineItemsFocusProperties(
        detailedLineItemSchema: DynamicGenerationSchema
    ) -> [DynamicGenerationSchema.Property] {
        [
            DynamicSchemaHelpers.typedProperty(
                "invoiceNumber",
                type: String.self,
                description: "Invoice number this line items belong to"
            ),
            DynamicSchemaHelpers.arrayProperty(
                "lineItems",
                elementSchema: detailedLineItemSchema,
                description: "Array of detailed line items"
            ),
            DynamicSchemaHelpers.typedProperty(
                "totalItems",
                type: Int.self,
                description: "Total number of line items"
            ),
            DynamicSchemaHelpers.typedProperty(
                "totalValue",
                type: Double.self,
                description: "Total value of all line items"
            )
        ]
    }
}
