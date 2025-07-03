//
//  DynamicSchemaExampleType.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import Foundation
import SwiftUI

enum DynamicSchemaExampleType: String, CaseIterable, Identifiable {
    case basicObject = "basic_object"
    case arraySchema = "array_schema"
    case enumSchema = "enum_schema"
    case nestedObjects = "nested_objects"
    case schemaReferences = "schema_references"
    case optionalFields = "optional_fields"
    case generationGuides = "generation_guides"
    case unionTypes = "union_types"
    case formBuilder = "form_builder"
    case errorHandling = "error_handling"
    case invoiceProcessing = "invoice_processing"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .basicObject:
            return "Basic Object Schema"
        case .arraySchema:
            return "Array Schemas"
        case .enumSchema:
            return "Enum Schemas"
        case .nestedObjects:
            return "Nested Objects"
        case .schemaReferences:
            return "Schema References"
        case .optionalFields:
            return "Optional vs Required"
        case .generationGuides:
            return "Generation Guides"
        case .unionTypes:
            return "Union Types (anyOf)"
        case .formBuilder:
            return "Dynamic Form Builder"
        case .errorHandling:
            return "Error Handling"
        case .invoiceProcessing:
            return "Invoice Processing"
        }
    }
    
    var subtitle: String {
        switch self {
        case .basicObject:
            return "Create simple object schemas at runtime"
        case .arraySchema:
            return "Arrays with min/max constraints"
        case .enumSchema:
            return "String enumerations and choices"
        case .nestedObjects:
            return "Complex nested object structures"
        case .schemaReferences:
            return "Schemas referencing other schemas"
        case .optionalFields:
            return "Handle optional and required fields"
        case .generationGuides:
            return "Apply constraints to generated values"
        case .unionTypes:
            return "Multiple type alternatives"
        case .formBuilder:
            return "Build forms dynamically from user input"
        case .errorHandling:
            return "Handle schema errors gracefully"
        case .invoiceProcessing:
            return "Real-world invoice data extraction"
        }
    }
    
    var icon: String {
        switch self {
        case .basicObject:
            return "doc.text"
        case .arraySchema:
            return "list.number"
        case .enumSchema:
            return "list.bullet"
        case .nestedObjects:
            return "folder.fill"
        case .schemaReferences:
            return "link"
        case .optionalFields:
            return "questionmark.circle"
        case .generationGuides:
            return "ruler"
        case .unionTypes:
            return "arrow.triangle.branch"
        case .formBuilder:
            return "rectangle.grid.1x2"
        case .errorHandling:
            return "exclamationmark.triangle"
        case .invoiceProcessing:
            return "doc.richtext"
        }
    }
    
    var complexity: Complexity {
        switch self {
        case .basicObject, .arraySchema, .enumSchema:
            return .beginner
        case .nestedObjects, .optionalFields, .generationGuides:
            return .intermediate
        case .schemaReferences, .unionTypes, .errorHandling:
            return .advanced
        case .formBuilder, .invoiceProcessing:
            return .expert
        }
    }
    
    enum Complexity {
        case beginner
        case intermediate
        case advanced
        case expert
        
        var color: Color {
            switch self {
            case .beginner:
                return .green
            case .intermediate:
                return .orange
            case .advanced:
                return .red
            case .expert:
                return .purple
            }
        }
        
        var label: String {
            switch self {
            case .beginner:
                return "Beginner"
            case .intermediate:
                return "Intermediate"
            case .advanced:
                return "Advanced"
            case .expert:
                return "Expert"
            }
        }
    }
}