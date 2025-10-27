//
//  GuidedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct GuidedDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var selectedGuideType = 0
    @State private var patternInput = "Generate 5 US phone numbers with extensions"
    @State private var rangeInput = "Generate prices between $10 and $100 for electronics"
    @State private var arrayInput = "Create a shopping list with 3-5 items each having 2-4 attributes"
    @State private var validationInput = "Generate valid email addresses for 5 employees at techcorp.com"

    private let guideTypes = [
        "Pattern Matching",
        "Number Ranges",
        "Array Constraints",
        "Complex Validation"
    ]

    var body: some View {
        ExampleViewBase(
            title: "Generation Guides",
            description: "Apply constraints to generated values using schema properties",
            defaultPrompt: patternInput,
            currentPrompt: bindingForSelectedGuide,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { executor.reset() },
            content: {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Guide Type Selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Constraint Type")
                        .font(.headline)

                    Picker("Guide Type", selection: $selectedGuideType) {
                        ForEach(0..<guideTypes.count, id: \.self) { index in
                            Text(guideTypes[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Guide explanation
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Label("How it works", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text(guideExplanation)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }

                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data with Constraints")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 250)
                    }
                }
            }
            .padding()
        }
    )
}

    private var currentInput: String {
        switch selectedGuideType {
        case 0: return patternInput
        case 1: return rangeInput
        case 2: return arrayInput
        case 3: return validationInput
        default: return ""
        }
    }

    private var bindingForSelectedGuide: Binding<String> {
        switch selectedGuideType {
        case 0: return $patternInput
        case 1: return $rangeInput
        case 2: return $arrayInput
        case 3: return $validationInput
        default: return .constant("")
        }
    }

    private var guideExplanation: String {
        switch selectedGuideType {
        case 0: return "Pattern constraints use regex to ensure generated strings match specific formats (e.g., phone numbers, postal codes, IDs)"
        case 1: return "Number range constraints limit numeric values to specified minimum and maximum bounds"
        case 2: return "Array constraints control the number of items in arrays using minimumElements and maximumElements"
        case 3: return "Complex validation combines multiple constraints like patterns, ranges, and enum values"
        default: return ""
        }
    }

    private func runExample() async {
        let schema = createSchema(for: selectedGuideType)

        await executor.execute(
            withPrompt: currentInput,
            schema: schema,
            formatResults: { output in
                if let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: formatted, encoding: .utf8) {

                    // Add validation summary
                    var result = "=== Generated Data ===\n" + jsonString
                    result += "\n\n=== Constraint Validation ==="
                    result += validateConstraints(json, for: selectedGuideType)

                    return result
                }
                return output
            }
        )
    }

    private func createPhoneDirectorySchema() -> DynamicGenerationSchema {
        let phoneEntrySchema = DynamicGenerationSchema(
            name: "PhoneEntry",
            description: "Phone directory entry",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Person's name",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "phoneNumber",
                    description: "US phone number",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.pattern(/\(\d{3}\) \d{3}-\d{4}/)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "extension",
                    description: "Extension",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.pattern(/x\d{3,4}/)]
                    ),
                    isOptional: true
                )
            ]
        )

        return DynamicGenerationSchema(
            name: "PhoneDirectory",
            description: "Phone directory",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "entries",
                    description: "Phone directory entries",
                    schema: DynamicGenerationSchema(
                        arrayOf: phoneEntrySchema,
                        minimumElements: 3,
                        maximumElements: 7
                    )
                )
            ]
        )
    }

    private func createProductCatalogSchema() -> DynamicGenerationSchema {
        let productSchema = DynamicGenerationSchema(
            name: "Product",
            description: "Product information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Product name",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Price in USD",
                    schema: DynamicGenerationSchema(
                        type: Double.self,
                        guides: [.range(10.0...100.0)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "stock",
                    description: "Stock quantity",
                    schema: DynamicGenerationSchema(
                        type: Int.self,
                        guides: [.minimum(0), .maximum(500)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "discount",
                    description: "Discount percentage",
                    schema: DynamicGenerationSchema(
                        type: Double.self,
                        guides: [.range(0...50)]
                    ),
                    isOptional: true
                )
            ]
        )

        return DynamicGenerationSchema(
            name: "ProductCatalog",
            description: "Product catalog",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "products",
                    description: "Product list",
                    schema: DynamicGenerationSchema(
                        arrayOf: productSchema,
                        minimumElements: 3,
                        maximumElements: 8
                    )
                )
            ]
        )
    }

    private func createSchema(for index: Int) -> DynamicGenerationSchema {
        switch index {
        case 0: // Pattern Matching
            return createPhoneDirectorySchema()

        case 1: // Number Ranges
            return createProductCatalogSchema()

        case 2: // Array Constraints
            // Create shopping item schema
            let shoppingItemSchema = DynamicGenerationSchema(
                name: "ShoppingItem",
                description: "Individual shopping item",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Item name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "quantity",
                        description: "Quantity needed",
                        schema: .init(type: Int.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "category",
                        description: "Item category",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "estimatedPrice",
                        description: "Estimated price",
                        schema: .init(type: Double.self)
                    )
                ]
            )

            let storeNameProperty = DynamicGenerationSchema.Property(
                name: "storeName",
                description: "Store name",
                schema: .init(type: String.self)
            )
            let itemsProperty = DynamicGenerationSchema.Property(
                name: "items",
                description: "Shopping list items",
                schema: .init(arrayOf: shoppingItemSchema)
            )
            let categoriesProperty = DynamicGenerationSchema.Property(
                name: "categories",
                description: "Item categories",
                schema: .init(arrayOf: .init(type: String.self)),
                isOptional: true
            )

            return DynamicGenerationSchema(
                name: "ShoppingList",
                description: "Shopping list with constraints",
                properties: [storeNameProperty, itemsProperty, categoriesProperty]
            )

        default: // Complex Validation
            let firstNameProperty = DynamicGenerationSchema.Property(
                name: "firstName",
                description: "First name (capitalized)",
                schema: .init(type: String.self)
            )
            let lastNameProperty = DynamicGenerationSchema.Property(
                name: "lastName",
                description: "Last name (capitalized)",
                schema: .init(type: String.self)
            )
            let emailProperty = DynamicGenerationSchema.Property(
                name: "email",
                description: "Company email address",
                schema: .init(type: String.self)
            )
            let departmentProperty = DynamicGenerationSchema.Property(
                name: "department",
                description: "Department name",
                schema: .init(type: String.self)
            )

            let employeeSchema = DynamicGenerationSchema(
                name: "Employee",
                description: "Employee information",
                properties: [firstNameProperty, lastNameProperty, emailProperty, departmentProperty]
            )

            let employeesProperty = DynamicGenerationSchema.Property(
                name: "employees",
                description: "Employee records",
                schema: .init(arrayOf: employeeSchema)
            )

            let companySchema = DynamicGenerationSchema(
                name: "CompanyDirectory",
                description: "Company employee directory",
                properties: [employeesProperty]
            )

            return companySchema
        }
    }

    private func validateConstraints(_ json: Any, for guideType: Int) -> String {
        guard let dict = json as? [String: Any] else { return "\nCould not validate" }

        var validations = [String]()

        switch guideType {
        case 0: // Pattern validation
            if let entries = dict["entries"] as? [[String: Any]] {
                validations.append("\nGenerated \(entries.count) phone entries")
                let validPhones = entries.filter { entry in
                    if let phone = entry["phoneNumber"] as? String {
                        return phone.range(of: "\\(\\d{3}\\) \\d{3}-\\d{4}", options: .regularExpression) != nil
                    }
                    return false
                }.count
                validations.append("\nAll \(validPhones) phone numbers match pattern")
            }

        case 1: // Range validation
            if let products = dict["products"] as? [[String: Any]] {
                let pricesInRange = products.filter { product in
                    if let price = product["price"] as? Double {
                        return price >= 10 && price <= 100
                    }
                    return false
                }.count
                validations.append("\nAll \(pricesInRange) prices within $10-$100 range")
            }

        case 2: // Array constraints
            if let items = dict["items"] as? [[String: Any]] {
                validations.append("\nShopping list has \(items.count) items")
                let itemsWithCategories = items.filter { item in
                    return item["category"] != nil
                }.count
                validations.append("\n\(itemsWithCategories) items have categories")
            }

        default:
            break
        }

        return validations.joined()
    }

    private var exampleCode: String {
        """
        // Using GenerationGuide constraints with DynamicGenerationSchema

        // 1. Pattern constraints for strings
        let phoneSchema = DynamicGenerationSchema(
            type: String.self,
            guides: [.pattern(/\\(\\d{3}\\) \\d{3}-\\d{4}/)]
        )

        // 2. Range constraints for numbers
        let priceSchema = DynamicGenerationSchema(
            type: Double.self,
            guides: [.range(10.0...100.0)]
        )

        // 3. Array length constraints
        let itemsSchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 3,
            maximumElements: 5
        )

        // 4. Enum constraints for valid values
        let categorySchema = DynamicGenerationSchema(
            type: String.self,
            guides: [.anyOf(["A", "B", "C"])]
        )

        // 5. Constant values for fixed fields
        let versionSchema = DynamicGenerationSchema(
            type: String.self,
            guides: [.constant("1.0")]
        )
        """
    }
}

#Preview {
    NavigationStack {
        GuidedDynamicSchemaView()
    }
}
