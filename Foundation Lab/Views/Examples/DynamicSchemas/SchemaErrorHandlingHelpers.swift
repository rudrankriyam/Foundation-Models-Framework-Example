//
//  SchemaErrorHandlingHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension SchemaErrorHandlingView {
    func createBasicProductSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Product",
            description: "Product information",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Product name",
                    isOptional: true
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "price",
                    type: Double.self,
                    guides: [.minimum(0.01)],
                    description: "Price in dollars",
                    isOptional: true
                ),
                DynamicSchemaHelpers.arrayProperty(
                    "colors",
                    elementSchema: .init(type: String.self),
                    description: "Available colors",
                    isOptional: true,
                    minimumElements: 1,
                    maximumElements: 10
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "weight",
                    type: Double.self,
                    guides: [.minimum(0.001)],
                    description: "Weight in kilograms",
                    isOptional: true
                )
            ]
        )
    }

    func createStrictProductSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "StrictProduct",
            description: "Product with all required fields",
            properties: [
                DynamicSchemaHelpers.guidedProperty(
                    "productId",
                    type: String.self,
                    guides: [.pattern(/^PROD-\d {6}$/)],
                    description: "Unique product identifier",
                    isOptional: false  // Required!
                ),
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Product name (required)",
                    isOptional: false
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "category",
                    type: String.self,
                    guides: [.anyOf(["Electronics", "Clothing", "Food", "Other"])],
                    description: "Product category (required)",
                    isOptional: false  // Required!
                ),
                DynamicSchemaHelpers.typedProperty(
                    "inStock",
                    type: Bool.self,
                    description: "Stock status (required)",
                    isOptional: false
                )
            ]
        )
    }

    func createTypeSensitiveProductSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "TypeSensitiveProduct",
            description: "Product with specific type requirements",
            properties: [
                DynamicSchemaHelpers.guidedProperty(
                    "itemCount",
                    type: Int.self,
                    guides: [.range(1...1000)],
                    description: "Number of items (must be integer)"
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "price",
                    type: Decimal.self,
                    guides: [.minimum(0.01)],
                    description: "Exact price with decimals"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "isAvailable",
                    type: Bool.self,
                    description: "Availability status (boolean)"
                ),
                DynamicSchemaHelpers.arrayProperty(
                    "tags",
                    elementSchema: .init(type: String.self),
                    description: "Product tags (array of strings)",
                    minimumElements: 1
                )
            ]
        )
    }

    func createValidatedProductSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "ValidatedProduct",
            description: "Product with strict validation rules",
            properties: [
                DynamicSchemaHelpers.guidedProperty(
                    "sku",
                    type: String.self,
                    guides: [.pattern(/^[A-Z] {3}-\d {3}-[A-Z] {3}$/)],
                    description: "SKU must match pattern ABC-123-XYZ"
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "price",
                    type: Double.self,
                    guides: [.range(10.0...999.99)],
                    description: "Price must be between $10 and $999.99"
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "discount",
                    type: Int.self,
                    guides: [.range(0...50)],
                    description: "Discount percentage (0-50%)",
                    isOptional: true
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "status",
                    type: String.self,
                    guides: [.anyOf(["active", "discontinued", "coming_soon"])],
                    description: "Product status (must be one of the allowed values)"
                ),
                DynamicSchemaHelpers.guidedProperty(
                    "rating",
                    type: Double.self,
                    guides: [.range(1.0...5.0)],
                    description: "Product rating (1.0 to 5.0 in 0.5 increments)",
                    isOptional: true
                )
            ]
        )
    }

    func scenarioDescription(for index: Int) -> String {
        switch index {
        case 0:
            return "Basic extraction with a well-formed schema. This should succeed without errors."
        case 1:
            return """
            The schema requires fields that might not be present in the input. \
            The system will make best effort to extract available data.
            """
        case 2:
            return """
            The input contains data that doesn't match the expected types. \
            The system will attempt type conversion where possible.
            """
        case 3:
            return "Complex validation rules that might fail. The system will provide detailed error information."
        default:
            return ""
        }
    }

    var exampleCode: String {
        """
        // Error handling strategies

        // 1. Make fields optional to handle missing data
        let flexibleSchema = DynamicGenerationSchema(
            name: "Product",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Price if available",
                    schema: DynamicGenerationSchema(type: Double.self),
                    isOptional: true
                )
            ]
        )

        // 2. Use clear descriptions for type guidance
        let guidedSchema = DynamicGenerationSchema.Property(
            name: "date",
            description: "Date in format YYYY-MM-DD",
            schema: DynamicGenerationSchema(type: String.self)
        )

        // 3. Handle errors gracefully
        do {
            let result = try await session.respond(
                to: Prompt(text),
                schema: schema
            )
        } catch {
            // Log error and try with more lenient schema
        }
        """
    }
}
