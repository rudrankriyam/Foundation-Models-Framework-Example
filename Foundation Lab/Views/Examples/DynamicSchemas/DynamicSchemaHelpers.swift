//
//  DynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

/// Shared helper functions for creating dynamic schemas
enum DynamicSchemaHelpers {
    /// Creates a property with a nested schema
    static func nestedProperty(
        _ name: String,
        schema: DynamicGenerationSchema,
        description: String? = nil,
        isOptional: Bool = false
    ) -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: name,
            description: description,
            schema: schema,
            isOptional: isOptional
        )
    }

    /// Creates a property for an array of schemas
    static func arrayProperty(
        _ name: String,
        elementSchema: DynamicGenerationSchema,
        description: String? = nil,
        isOptional: Bool = false
    ) -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: name,
            description: description,
            schema: .init(arrayOf: elementSchema),
            isOptional: isOptional
        )
    }

    /// Creates a simple schema with properties
    static func schema(
        _ name: String,
        description: String? = nil,
        properties: [DynamicGenerationSchema.Property]
    ) -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: name,
            description: description,
            properties: properties
        )
    }
}
