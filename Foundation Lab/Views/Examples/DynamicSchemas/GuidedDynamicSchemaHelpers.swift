//
//  GuidedDynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension GuidedDynamicSchemaView {
    func createPhoneDirectorySchema() -> DynamicGenerationSchema {
        let phoneEntrySchema = DynamicSchemaHelpers.schema(
            "PhoneEntry",
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
                        guides: [.pattern(/\(\d {3}\) \d {3}-\d {4}/)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "extension",
                    description: "Extension",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.pattern(/x\d {3,4}/)]
                    ),
                    isOptional: true
                )
            ]
        )

        return DynamicSchemaHelpers.schema(
            "PhoneDirectory",
            description: "Phone directory",
            properties: [
                DynamicSchemaHelpers.arrayProperty(
                    "entries",
                    elementSchema: phoneEntrySchema,
                    description: "Phone directory entries",
                    minimumElements: 3,
                    maximumElements: 7
                )
            ]
        )
    }

    func createProductCatalogSchema() -> DynamicGenerationSchema {
        let productSchema = DynamicSchemaHelpers.schema(
            "Product",
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

        return DynamicSchemaHelpers.schema(
            "ProductCatalog",
            description: "Product catalog",
            properties: [
                DynamicSchemaHelpers.arrayProperty(
                    "products",
                    elementSchema: productSchema,
                    description: "Product list",
                    minimumElements: 3,
                    maximumElements: 8
                )
            ]
        )
    }

    func createShoppingListSchema() -> DynamicGenerationSchema {
        let shoppingItemSchema = DynamicSchemaHelpers.schema(
            "ShoppingItem",
            description: "Individual shopping item",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Item name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "quantity",
                    type: Int.self,
                    description: "Quantity needed"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "category",
                    type: String.self,
                    description: "Item category"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "estimatedPrice",
                    type: Double.self,
                    description: "Estimated price"
                )
            ]
        )

        let storeNameProperty = DynamicSchemaHelpers.typedProperty(
            "storeName",
            type: String.self,
            description: "Store name"
        )

        let stringSchema = DynamicGenerationSchema(type: String.self)
        let itemsProperty = DynamicSchemaHelpers.arrayProperty(
            "items",
            elementSchema: shoppingItemSchema,
            description: "Shopping list items"
        )
        let categoriesProperty = DynamicSchemaHelpers.arrayProperty(
            "categories",
            elementSchema: stringSchema,
            description: "Item categories",
            isOptional: true
        )

        return DynamicSchemaHelpers.schema(
            "ShoppingList",
            description: "Shopping list with constraints",
            properties: [storeNameProperty, itemsProperty, categoriesProperty]
        )
    }

    func createCompanyDirectorySchema() -> DynamicGenerationSchema {
        let firstNameProperty = DynamicSchemaHelpers.typedProperty(
            "firstName",
            type: String.self,
            description: "First name (capitalized)"
        )
        let lastNameProperty = DynamicSchemaHelpers.typedProperty(
            "lastName",
            type: String.self,
            description: "Last name (capitalized)"
        )
        let emailProperty = DynamicSchemaHelpers.typedProperty(
            "email",
            type: String.self,
            description: "Company email address"
        )
        let departmentProperty = DynamicSchemaHelpers.typedProperty(
            "department",
            type: String.self,
            description: "Department name"
        )

        let employeeSchema = DynamicSchemaHelpers.schema(
            "Employee",
            description: "Employee information",
            properties: [firstNameProperty, lastNameProperty, emailProperty, departmentProperty]
        )

        let employeesProperty = DynamicSchemaHelpers.arrayProperty(
            "employees",
            elementSchema: employeeSchema,
            description: "Employee records"
        )

        return DynamicSchemaHelpers.schema(
            "CompanyDirectory",
            description: "Company employee directory",
            properties: [employeesProperty]
        )
    }

    func validateConstraints(_ json: Any, for guideType: Int) -> String {
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
}
