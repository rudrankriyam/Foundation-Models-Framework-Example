//
//  ArrayDynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension ArrayDynamicSchemaView {
    func createSchema(for index: Int, minItems: Int, maxItems: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            // Todo items array
            let todoItemSchema = DynamicGenerationSchema(
                name: "TodoItem",
                description: "A single todo task",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "task",
                        description: "The task description",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "priority",
                        description: "Priority level (high, medium, low)",
                        schema: .init(name: "Priority", anyOf: ["high", "medium", "low"]),
                        isOptional: true
                    )
                ]
            )

            let arraySchema = DynamicGenerationSchema(
                arrayOf: todoItemSchema,
                minimumElements: minItems,
                maximumElements: maxItems
            )

            return try GenerationSchema(root: arraySchema, dependencies: [todoItemSchema])

        case 1:
            // Recipe ingredients array
            let ingredientSchema = DynamicGenerationSchema(
                name: "Ingredient",
                description: "A recipe ingredient",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Ingredient name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "quantity",
                        description: "Amount needed",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )

            let arraySchema = DynamicGenerationSchema(
                arrayOf: ingredientSchema,
                minimumElements: minItems,
                maximumElements: maxItems
            )

            return try GenerationSchema(root: arraySchema, dependencies: [ingredientSchema])

        default:
            // Simple string array for tags
            let stringSchema = DynamicGenerationSchema(type: String.self)
            let arraySchema = DynamicGenerationSchema(
                arrayOf: stringSchema,
                minimumElements: minItems,
                maximumElements: maxItems
            )

            return try GenerationSchema(root: arraySchema, dependencies: [])
        }
    }

    func schemaInfo(for index: Int, minItems: Int, maxItems: Int) -> String {
        let itemType = index == 0 ? "TodoItem" : index == 1 ? "Ingredient" : "Tag"
        return """
        This will extract an array of \(itemType) objects.
        • Minimum items: \(minItems)
        • Maximum items: \(maxItems)
        • The model will respect these constraints when generating the array.
        """
    }

    func formatItems(_ items: [GeneratedContent]) -> String {
        var result = ""
        for (index, item) in items.enumerated() {
            result += "\n\(index + 1). "

            // Try to format as object with properties
            switch item.kind {
            case .structure(let properties, _):
                var parts: [String] = []
                for (key, value) in properties {
                    switch value.kind {
                    case .string(let stringValue):
                        parts.append("\(key): \(stringValue)")
                    case .number(let numValue):
                        parts.append("\(key): \(numValue)")
                    case .bool(let boolValue):
                        parts.append("\(key): \(boolValue)")
                    default:
                        break
                    }
                }
                result += parts.joined(separator: ", ")
            case .string(let stringValue):
                // Format as simple string
                result += stringValue
            default:
                result += "Unknown item"
            }
        }
        return result
    }

    var exampleCode: String {
        """
        // Creating an array schema with constraints
        let itemSchema = DynamicGenerationSchema(
            name: "TodoItem",
            description: "A single todo task",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "task",
                    description: "The task description",
                    schema: .init(type: String.self)
                )
            ]
        )

        // Array with min/max constraints
        let arraySchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 2,
            maximumElements: 5
        )

        let schema = try GenerationSchema(
            root: arraySchema,
            dependencies: [itemSchema]
        )

        // The model will generate between 2 and 5 items
        let response = try await session.respond(
            to: prompt,
            schema: schema
        )

        // Edge cases handled:
        // - Empty arrays (if minimum is 0)
        // - Maximum element enforcement
        // - Nested object arrays
        // - Simple string arrays
        """
    }
}
