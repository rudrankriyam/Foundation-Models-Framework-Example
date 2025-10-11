//
//  InvoiceProcessingSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct InvoiceProcessingSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var invoiceText = """
    INVOICE #2025-001
    Date: January 15, 2025
    Due Date: February 14, 2025

    From:
    TechCorp Solutions Inc.
    123 Innovation Drive
    San Francisco, CA 94105
    Tax ID: 87-1234567

    Bill To:
    Acme Corporation
    456 Business Blvd
    New York, NY 10001

    Description                          Qty    Unit Price    Amount
    ----------------------------------------------------------------
    Software Development Services         80     $150.00    $12,000.00
    Cloud Infrastructure Setup            1     $2,500.00    $2,500.00
    Monthly Support Package               3       $800.00    $2,400.00
    Security Audit                        1     $3,200.00    $3,200.00

    Subtotal:                                              $20,100.00
    Tax (8.875%):                                           $1,783.88
    ----------------------------------------------------------------
    Total Due:                                             $21,883.88

    Payment Terms: Net 30
    Please include invoice number with payment.
    """

    @State private var extractionMode = 0
    @State private var includeLineItems = true
    @State private var calculateTotals = true

    private let modes = ["Full Invoice", "Summary Only", "Line Items Focus"]

    var body: some View {
        ExampleViewBase(
            title: "Invoice Processing",
            description: "Extract structured data from real-world invoices using complex schemas",
            defaultPrompt: invoiceText,
            currentPrompt: $invoiceText,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { executor.reset() }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Mode selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Extraction Mode")
                        .font(.headline)

                    Picker("Mode", selection: $extractionMode) {
                        ForEach(0..<modes.count, id: \.self) { index in
                            Text(modes[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Options
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Toggle("Extract line items", isOn: $includeLineItems)
                        .disabled(extractionMode == 1) // Disabled for summary only

                    Toggle("Validate calculations", isOn: $calculateTotals)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)

                // Sample invoice loader
                HStack {
                    Spacer()
                    Button("Load Sample Invoice") {
                        loadSampleInvoice()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }

                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Extracted Invoice Data")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding()
        }
    }

    private func loadSampleInvoice() {
        invoiceText = """
        INVOICE
        Invoice Number: INV-2025-0042
        Date: March 1, 2025

        Seller:
        Creative Agency LLC
        789 Design Street, Suite 200
        Los Angeles, CA 90028
        Email: billing@creativeagency.com
        Phone: (323) 555-0100

        Buyer:
        StartUp Inc.
        321 Venture Ave
        Austin, TX 78701
        Contact: Sarah Johnson

        Items:
        1. Logo Design and Branding Package
           Quantity: 1
           Rate: $5,000.00
           Amount: $5,000.00

        2. Website Design (10 pages)
           Quantity: 10
           Rate: $500.00 per page
           Amount: $5,000.00

        3. Social Media Templates
           Quantity: 20
           Rate: $75.00 each
           Amount: $1,500.00

        4. Brand Guidelines Document
           Quantity: 1
           Rate: $1,200.00
           Amount: $1,200.00

        Subtotal: $12,700.00
        Discount (10%): -$1,270.00
        Net Amount: $11,430.00
        Sales Tax (7.25%): $828.68

        Total Amount Due: $12,258.68

        Payment Due: March 31, 2025
        Late Fee: 1.5% per month after due date
        """
    }

    private func runExample() async {
        let schema: DynamicGenerationSchema

        switch extractionMode {
        case 0: // Full Invoice
            schema = createFullInvoiceSchema()
        case 1: // Summary Only
            schema = createSummarySchema()
        case 2: // Line Items Focus
            schema = createLineItemsSchema()
        default:
            return
        }

        await executor.execute(
            withPrompt: invoiceText,
            schema: schema,
            formatResults: { output in
                if let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: formatted, encoding: .utf8) {

                    var result = jsonString

                    // Add validation results if enabled
                    if calculateTotals, let dict = json as? [String: Any] {
                        result += "\n\n=== Validation Results ==="
                        result += validateInvoiceTotals(dict)
                    }

                    return result
                }
                return output
            }
        )
    }

    private func createFullInvoiceSchema() -> DynamicGenerationSchema {
        // Address schema for reuse
        let addressSchema = DynamicGenerationSchema(
            name: "Address",
            description: "Address information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "company",
                    description: "Company name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "street",
                    description: "Street address",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "city",
                    description: "City",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "state",
                    description: "State/Province",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "postalCode",
                    description: "ZIP/Postal code",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "country",
                    description: "Country",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "taxId",
                    description: "Tax ID or registration number",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/\d{2}-\d{7}/)]
                    ),
                    isOptional: true
                )
            ]
        )

        // Line item schema
        let lineItemSchema = DynamicGenerationSchema(
            name: "LineItem",
            description: "Invoice line item",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "description",
                    description: "Item description",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "quantity",
                    description: "Quantity",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.001)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "unitPrice",
                    description: "Price per unit",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.01)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "amount",
                    description: "Total amount for this line",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    )
                )
            ]
        )

        // Payment terms schema
        let paymentTermsSchema = DynamicGenerationSchema(
            name: "PaymentTerms",
            description: "Payment terms and conditions",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "terms",
                    description: "Payment terms (e.g., Net 30)",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "dueDate",
                    description: "Payment due date",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "lateFee",
                    description: "Late fee policy if specified",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )

        // Main invoice schema
        return DynamicGenerationSchema(
            name: "Invoice",
            description: "Complete invoice information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "invoiceNumber",
                    description: "Invoice number or ID",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "invoiceDate",
                    description: "Invoice issue date",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "seller",
                    description: "Seller/vendor information",
                    schema: addressSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "buyer",
                    description: "Buyer/customer information",
                    schema: addressSchema
                ),
                DynamicGenerationSchema.Property(
                    name: "lineItems",
                    description: "Individual line items",
                    schema: .init(arrayOf: lineItemSchema)
                ),
                DynamicGenerationSchema.Property(
                    name: "subtotal",
                    description: "Subtotal before tax/discount",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "discount",
                    description: "Discount information if any",
                    schema: DynamicGenerationSchema(
                        name: "Discount",
                        description: "Discount information",
                        properties: [
                            DynamicGenerationSchema.Property(
                                name: "percentage",
                                description: "Discount percentage",
                                schema: .init(
                                    type: Double.self,
                                    guides: [.range(0.0...100.0)]
                                ),
                                isOptional: true
                            ),
                            DynamicGenerationSchema.Property(
                                name: "amount",
                                description: "Discount amount",
                                schema: .init(
                                    type: Double.self,
                                    guides: [.minimum(0.0)]
                                ),
                                isOptional: true
                            )
                        ]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "tax",
                    description: "Tax information",
                    schema: DynamicGenerationSchema(
                        name: "Tax",
                        description: "Tax information",
                        properties: [
                            DynamicGenerationSchema.Property(
                                name: "rate",
                                description: "Tax rate percentage",
                                schema: .init(
                                    type: Double.self,
                                    guides: [.range(0.0...100.0)]
                                )
                            ),
                            DynamicGenerationSchema.Property(
                                name: "amount",
                                description: "Tax amount",
                                schema: .init(
                                    type: Double.self,
                                    guides: [.minimum(0.0)]
                                )
                            )
                        ]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "totalAmount",
                    description: "Total amount due",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "paymentTerms",
                    description: "Payment terms and conditions",
                    schema: paymentTermsSchema,
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "notes",
                    description: "Additional notes or instructions",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )
    }

    private func createSummarySchema() -> DynamicGenerationSchema {
        return DynamicGenerationSchema(
            name: "InvoiceSummary",
            description: "Invoice summary information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "invoiceNumber",
                    description: "Invoice number",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "date",
                    description: "Invoice date",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "sellerName",
                    description: "Seller company name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "buyerName",
                    description: "Buyer company name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "totalAmount",
                    description: "Total amount due",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "currency",
                    description: "Currency if specified",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "dueDate",
                    description: "Payment due date",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "status",
                    description: "Invoice status",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )
    }

    private func createLineItemsSchema() -> DynamicGenerationSchema {
        let detailedLineItemSchema = DynamicGenerationSchema(
            name: "DetailedLineItem",
            description: "Detailed line item information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "lineNumber",
                    description: "Line item number",
                    schema: .init(
                        type: Int.self,
                        guides: [.minimum(1)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "description",
                    description: "Detailed item description",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "category",
                    description: "Item category",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "quantity",
                    description: "Quantity",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.001)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "unit",
                    description: "Unit of measurement",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "unitPrice",
                    description: "Price per unit",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.01)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "amount",
                    description: "Line total",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "taxable",
                    description: "Is this item taxable",
                    schema: .init(type: Bool.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "notes",
                    description: "Additional notes for this item",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )

        return DynamicGenerationSchema(
            name: "LineItemsExtraction",
            description: "Line items extraction result",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "invoiceNumber",
                    description: "Invoice reference",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "lineItems",
                    description: "All line items from the invoice",
                    schema: .init(arrayOf: detailedLineItemSchema)
                ),
                DynamicGenerationSchema.Property(
                    name: "itemCount",
                    description: "Total number of line items",
                    schema: .init(
                        type: Int.self,
                        guides: [.minimum(0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "subtotal",
                    description: "Sum of all line items",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "averageItemValue",
                    description: "Average value per line item",
                    schema: .init(
                        type: Double.self,
                        guides: [.minimum(0.0)]
                    ),
                    isOptional: true
                )
            ]
        )
    }

    private func validateInvoiceTotals(_ invoice: [String: Any]) -> String {
        var validationResults = [String]()

        // Validate subtotal calculation
        if let lineItems = invoice["lineItems"] as? [[String: Any]] {
            let calculatedSubtotal = lineItems.reduce(0.0) { sum, item in
                sum + (item["amount"] as? Double ?? 0)
            }

            if let reportedSubtotal = invoice["subtotal"] as? Double {
                let difference = abs(calculatedSubtotal - reportedSubtotal)
                if difference < 0.01 {
                    validationResults.append("\nSubtotal calculation is correct: $\(String(format: "%.2f", reportedSubtotal))")
                } else {
                    validationResults.append("\nSubtotal mismatch: Calculated $\(String(format: "%.2f", calculatedSubtotal)) vs Reported $\(String(format: "%.2f", reportedSubtotal))")
                }
            }
        }

        // Validate tax calculation
        if let tax = invoice["tax"] as? [String: Any],
           let taxRate = tax["rate"] as? Double,
           let taxAmount = tax["amount"] as? Double,
           let subtotal = invoice["subtotal"] as? Double {

            let calculatedTax = subtotal * (taxRate / 100)
            let difference = abs(calculatedTax - taxAmount)
            if difference < 0.01 {
                validationResults.append("\nTax calculation is correct: \(taxRate)% = $\(String(format: "%.2f", taxAmount))")
            } else {
                validationResults.append("\nTax calculation mismatch: Expected $\(String(format: "%.2f", calculatedTax)), got $\(String(format: "%.2f", taxAmount))")
            }
        }

        // Validate total
        if let total = invoice["totalAmount"] as? Double,
           let _ = invoice["subtotal"] as? Double {
            validationResults.append("\nTotal amount extracted: $\(String(format: "%.2f", total))")
        }

        return validationResults.joined()
    }

    private var exampleCode: String {
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

#Preview {
    NavigationStack {
        InvoiceProcessingSchemaView()
    }
}
