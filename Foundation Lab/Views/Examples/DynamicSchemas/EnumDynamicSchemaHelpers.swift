//
//  EnumDynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

struct ClassificationData {
    let classification: String
    let confidence: Float?
    let reasoning: String?
}

extension EnumDynamicSchemaView {
    func extractClassificationData(from content: GeneratedContent, fieldName: String) -> ClassificationData {
        switch content.kind {
        case .structure(let properties, _):
            let classification = extractStringValue(from: properties[fieldName])
            let confidence = extractFloatValue(from: properties["confidence"])
            let reasoning = extractStringValue(from: properties["reasoning"])
            return ClassificationData(classification: classification, confidence: confidence, reasoning: reasoning)
        default:
            return ClassificationData(classification: "unknown", confidence: nil, reasoning: nil)
        }
    }

    func extractStringValue(from content: GeneratedContent?) -> String {
        guard let content = content else { return "unknown" }
        if case .string(let str) = content.kind {
            return str
        }
        return "unknown"
    }

    func extractFloatValue(from content: GeneratedContent?) -> Float? {
        guard let content = content else { return nil }
        if case .number(let num) = content.kind {
            return Float(num)
        }
        return nil
    }

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
