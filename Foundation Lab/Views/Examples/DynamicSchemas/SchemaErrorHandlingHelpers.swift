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
        DynamicGenerationSchema(
            name: "Product",
            description: "Product information",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Product name",
                    schema: DynamicGenerationSchema(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Price in dollars",
                    schema: DynamicGenerationSchema(
                        type: Double.self,
                        guides: [.minimum(0.01)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "colors",
                    description: "Available colors",
                    schema: DynamicGenerationSchema(
                        arrayOf: DynamicGenerationSchema(type: String.self),
                        minimumElements: 1,
                        maximumElements: 10
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "weight",
                    description: "Weight in kilograms",
                    schema: DynamicGenerationSchema(
                        type: Double.self,
                        guides: [.minimum(0.001)]
                    ),
                    isOptional: true
                )
            ]
        )
    }

    func createStrictProductSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "StrictProduct",
            description: "Product with all required fields",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "productId",
                    description: "Unique product identifier",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.pattern(/^PROD-\d {6}$/)]
                    ),
                    isOptional: false  // Required!
                ),
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Product name (required)",
                    schema: DynamicGenerationSchema(type: String.self),
                    isOptional: false  // Required!
                ),
                DynamicGenerationSchema.Property(
                    name: "category",
                    description: "Product category (required)",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.anyOf(["Electronics", "Clothing", "Food", "Other"])]
                    ),
                    isOptional: false  // Required!
                ),
                DynamicGenerationSchema.Property(
                    name: "inStock",
                    description: "Stock status (required)",
                    schema: DynamicGenerationSchema(type: Bool.self),
                    isOptional: false  // Required!
                )
            ]
        )
    }

    func createTypeSensitiveProductSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "TypeSensitiveProduct",
            description: "Product with specific type requirements",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "itemCount",
                    description: "Number of items (must be integer)",
                    schema: DynamicGenerationSchema(
                        type: Int.self,
                        guides: [.range(1...1000)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Exact price with decimals",
                    schema: DynamicGenerationSchema(
                        type: Decimal.self,
                        guides: [.minimum(0.01)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "isAvailable",
                    description: "Availability status (boolean)",
                    schema: DynamicGenerationSchema(type: Bool.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "tags",
                    description: "Product tags (array of strings)",
                    schema: DynamicGenerationSchema(
                        arrayOf: DynamicGenerationSchema(type: String.self),
                        minimumElements: 1
                    )
                )
            ]
        )
    }

    func createValidatedProductSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "ValidatedProduct",
            description: "Product with strict validation rules",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "sku",
                    description: "SKU must match pattern ABC-123-XYZ",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.pattern(/^[A-Z] {3}-\d {3}-[A-Z] {3}$/)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Price must be between $10 and $999.99",
                    schema: DynamicGenerationSchema(
                        type: Double.self,
                        guides: [.range(10.0...999.99)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "discount",
                    description: "Discount percentage (0-50%)",
                    schema: DynamicGenerationSchema(
                        type: Int.self,
                        guides: [.range(0...50)]
                    ),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "status",
                    description: "Product status (must be one of the allowed values)",
                    schema: DynamicGenerationSchema(
                        type: String.self,
                        guides: [.anyOf(["active", "discontinued", "coming_soon"])]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "rating",
                    description: "Product rating (1.0 to 5.0 in 0.5 increments)",
                    schema: DynamicGenerationSchema(
                        type: Double.self,
                        guides: [.range(1.0...5.0)]
                    ),
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
