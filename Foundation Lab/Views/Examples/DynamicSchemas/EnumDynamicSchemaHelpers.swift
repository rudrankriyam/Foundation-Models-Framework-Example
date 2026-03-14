//
//  EnumDynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation

extension EnumDynamicSchemaView {
    var exampleCode: String {
        """
        // Creating an enum schema with string choices
        let sentimentSchema = DynamicGenerationSchema(
            name: "Sentiment",
            description: "Sentiment classification",
            anyOf: ["positive", "negative", "neutral", "mixed"]
        )

        // Use the enum in a property
        let sentimentProperty = DynamicGenerationSchema.Property(
            name: "sentiment",
            description: "The sentiment of the text",
            schema: sentimentSchema
        )

        let resultSchema = DynamicGenerationSchema(
            name: "Result",
            properties: [sentimentProperty]
        )

        let schema = try GenerationSchema(
            root: resultSchema,
            dependencies: [sentimentSchema]
        )

        // The model will only choose from the provided options
        // Edge cases:
        // - Empty choices array (will throw error)
        // - Duplicate choices (handled gracefully)
        // - Case sensitivity (choices are case-sensitive)
        // - Dynamic choice generation at runtime
        """
    }
}
